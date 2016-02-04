#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# ruby で綴る VM interface

require "pp"
require "socket"

################
# バイトオーダー変換の機能を追加
class Integer
  def htonl
    [self].pack("L!").unpack("N")[0]
  end
  def htons
    [self].pack("S!").unpack("n")[0]
  end
  def ntohl
    [self].pack("N").unpack("L!")[0]
  end
  def ntohs
    [self].pack("n").unpack("S!")[0]
  end
end

class NWDIY
  ################################################################
  # Linux 関連
  class Linux

    # /usr/include/linux/if_ether.h
    ETH_P_ALL = "0x0003".hex

    # /usr/include/bits/socket.h
    PF_PACKET = 17
    AF_PACKET = 17
    SOCK_RAW  = Socket::SOCK_RAW
    SOL_PACKET = 263

    # /usr/include/linux/if_packet.h
    PACKET_ADD_MEMBERSHIP = 1
    PACKET_MR_PROMISC = 1

    # アプリと root 権限デーモンとのやりとりソケット
    DAEMON_SOCKFILE = '/tmp/.nwdiy_daemon'

    ################
    # 数値あるいは文字列から ifindex と ifname を求める
    def self.ifindexname(arg)
      iflist = `ip link`.scan(/^(\d+): (\w+): /)
      iflist.each do |link|
        (link[0] == arg || link[1] == arg) and return [link[0].to_i, link[1]]
      end
      raise ArgumentError.new("Unknown device: #{arg} in #{iflist}");
    end

    ################
    # sockaddr_ll を作る
    def self.pack_sockaddr_ll(index)
      [AF_PACKET, ETH_P_ALL, index].pack("S!nIx12")
    end
  end

  ################################################################
  # インターフェース
  class IFP
    ################
    # new 引数はインターフェース名、あるいは情報付与したハッシュ
    def initialize(arg)

      arg or raise ArgumentError.new("no interface: #{arg}");

      if arg.kind_of?(String)
        begin
          @dev = NWDIY::IFP::Pcap.new(arg)
        rescue Errno::EPERM
          @dev = NWDIY::IFP::Proxy.new(NWDIY::IFP::Pcap, arg)
        rescue ArgumentError
          @dev = NWDIY::IFP::Sock.new(arg)
        end
      end

      if arg.kind_of?(Hash)
        case arg[:type]
        when :pcap
          begin
            @dev = NWDIY::IFP::Pcap.new(arg[:name])
          rescue Errno::EPERM
            @dev = NWDIY::IFP::Proxy.new(NWDIY::IFP::Pcap, arg[:name])
          end
        when :sock
          @dev = NWDIY::IFP::Sock.new(arg[:name])
        when :tap
          @dev = NWDIY::IFP::Tap.new(arg[:name])
        else
          raise ArgumentError.new("Unknown interface type: #{arg[:type]}")
        end
      end
    end

    ################
    # socket operations
    def close
      @dev.close
    end
    def send(msg)
      @dev.send(msg)
    end

    ################################################################
    # pcap
    class Pcap < Linux
      ################
      # Linux では AF_PACKET を使ってパケットを送受信する
      def initialize(name)
        index, name = self.class.ifindexname(name)
        @sock = Socket.new(PF_PACKET, SOCK_RAW, ETH_P_ALL.htons)
        @sock.bind(self.class.pack_sockaddr_ll(index))
        self.clean
        self.set_promisc(index)
      end

      ################
      # ソケット掃除
      def clean
        buf = ""
        loop do
          begin
            @sock.read_nonblock(1, buf)
          rescue Errno::EAGAIN, Errno::EWOULDBLOCK
            return nil
          rescue Errno::EINTR
          end
        end
      end

      ################
      # パケット送受信モード
      def set_promisc(index)
        @sock.setsockopt(SOL_PACKET, PACKET_ADD_MEMBERSHIP, [index, PACKET_MR_PROMISC].pack("I!S!x10"))
      end

      ################
      # socket operations
      def close
        @sock.close
      end
      def send(msg)
        pp msg
        msg.length
      end

    end

    ################################################################
    # socket
    class Sock

      ################
      # UNIX domain socket でパケットを送受信する
      def initialize(ifname)
      end
    end

    ################################################################
    # 既に起動してあるデーモンと Marshal Dump 経由でパケット送受信する
    class Proxy < Linux
      attr_reader(:klass, :name)

      def initialize(klass, name)
        @klass, @name = klass, name
        begin
          sock = UNIXSocket.new(DAEMON_SOCKFILE)
        rescue Errno::ENOENT, Errno::ECONNREFUSED => e
          raise e.class.new('Please run NW-DIY daemon')
        end
        Marshal.dump(self, sock)
        @sock = sock;
      end

      ################
      # socket operations
      def close
        @sock.close
      end
      def send(msg)
        Marshal.dump(msg, @sock)
        msg.length
      end

      ################################################################
      # Proxy を処理するデーモン
      class Daemon < Linux

        # NWDIY アプリからの接続を待ち受けるソケットを作る
        def run
          begin
            umask = File.umask
            File.umask(000)
            @sock = UNIXServer.new(DAEMON_SOCKFILE)
            File.umask(umask)
          rescue Errno::EADDRINUSE => e
            begin
              UNIXSocket.new(DAEMON_SOCKFILE)
              raise e
            rescue Errno::ECONNREFUSED
              umask = File.umask
              File.umask(000)
              File.unlink(DAEMON_SOCKFILE)
              @sock = UNIXServer.new(DAEMON_SOCKFILE)
              File.umask(umask)
            end
          end
          begin
            while accept = @sock.accept
              NWDIY::IFP::Proxy::Daemon::Client.new(accept).start
            end
          ensure
            File.unlink(DAEMON_SOCKFILE)
          end
        end

        ################################################################
        # Daemon から NWDIY アプリを見る
        class Client
          def initialize(sock)
            @app = sock
            @dev = {}
            puts "opened: #{@app.to_i}"
          end
          def start
            @thread = Thread.new { self.run }
          end
          def run
            begin
              self.recvall
            rescue => e
              puts "ERROR: #{e}"
            ensure
              puts "closed: #{@app.to_i}"
              @app.close
              @dev.close
              pp self
            end
          end

          ################
          # NWDIY アプリからのメッセージを待ち受けてさばく
          def recvall
            loop do
              begin
                data = Marshal.load(@app)
              rescue EOFError
                return
              end
              if data.kind_of?(NWDIY::IFP::Proxy)
                self.create(data.klass, data.name)
                next
              end
              self.send(data)
            end
          end

          ################
          # 新しいインターフェースを開く
          def create(klass, name)
            puts klass, name
            @dev = klass.new(name)
            puts @dev
          end

          ################
          # socket operations
          def send(msg)
            @dev.send(msg)
          end
        end
      end
    end
  end
end

if $0 == __FILE__
  NWDIY::IFP::Proxy::Daemon.new.run
end
