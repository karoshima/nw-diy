#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require "io/wait"
require "nwdiy"

class Nwdiy::Func::Out < Nwdiy::Func

  include Nwdiy::Debug

  def initialize(arg)
    case arg
    when String
      begin
        begin
          @sock = TCPSocket.new("::1", $NWDIY_INTERFACE_PROXY_PORT)
        rescue Errno::ECONNREFUSED => e
          debug("#{e}")
          self.class.start_server
          retry
        end
        @sock.syswrite(arg) # プロキシにインターフェース名を通知して
        @sock.sysread(1024)  # Ack をもらう
      end
    when Socket
      @sock = arg  # self.pair で生成されたソケットを使うようにする
    end
  end

  def self.pair
    Socket.socketpair(Socket::AF_INET6, Socket::SOCK_STREAM).map do |so| 
      self.new(so)
    end
  end

  def on
    # on 前のものは無かったことにしてから on にする
    while @sock.ready?
      @sock.sysread(1024)
    end
    super()
  end

  def ready?
    self.power && @sock.ready?
  end

  def recv
    return nil unless self.power
    @sock.sysread(65536)
  end

  def send(pkt)
    @sock.syswrite(pkt.to_s)
  end

  ################################################################
  # パケット受け渡しデーモン

  def self.start_server

    # 待ち受けソケット
    @@sock = TCPServer.new("::1", $NWDIY_INTERFACE_PROXY_PORT)
    debug("listening #{@@sock}")

    # インターフェース名ごとの、Nwdiy::Func::Out インスタンス配列
    @@peer = Hash.new { |hash,key| hash[key] = Array.new }

    # ファイルデスクリプタごとの、インターフェース名
    @@name = Array.new

    # インターフェース名ごとの、OS インターフェース
    @@os = Hash.new

    @@thread = Thread.new do
      loop do

        check = [@@sock]
        check += @@peer.values.flatten
        check += @@os.values.compact

        debug("waiting #{check}")

        can_read, = IO.select(check)
        can_read.each do |io|

          debug(self, "accepted on #{io}")

          if io == @@sock
            accept_newsock(io)
          else
            recv_data(io)
          end
        end
      end
    end

    debug("thread #{@@thread}")
    @@thread
  end

  # 新しいアクセスが来たのでインターフェース名を教えてもらって登録する
  def self.accept_newsock(sock)
    acc = sock.accept
    begin
      ifname = acc.sysread(1024)
      debug(self, "ifname #{ifname}")
    rescue EOFError
      return
    end

    # @@peer と @@name に登録する
    @@peer[ifname] << acc
    @@name[acc.fileno] = ifname

    # 可能なら @@os ソケットを開いて登録する
    unless @@os.has_key?(ifname)
      @@os[ifname] = nil
      Socket.getifaddrs.each do |ifa|
        next unless ifa.name == ifname
        begin
          debug("try OS interface")
          os = Socket.new(Socket::AF_PACKET, Socket::SOCK_RAW, Nwdiy::ETH_P_ALL.htons)
          os.bind(Socket.pack_sockaddr_ll(Nwdiy::ETH_P_ALL, ifa.ifindex))
          self.clean_ossock(os)
          self.set_promisc(ifa.ifindex, os)
          @@os[ifname] = os
          @@name[os.fileno] = ifname
        rescue Errno::EPERM => e
          debug("#{e} on OS interface")
        end
        break
      end
    end

    # 最後に Ack を返す
    acc.syswrite(ifname)
  end

  # Socket.new してから bind() するまでの間に受信しちゃったパケットは
  # 関係ないインターフェースに来たものがいっぱいなので
  # 掃除しちゃう
  def self.clean_ossock(sock)
    buf = ""
    loop do
      begin
        sock.read_nonblock(1, buf)
      rescue Errno::EAGAIN, Errno::EWOULDBLOCK
        return # DONE
      rescue Errno::EINTR
        # retry
      end
    end
  end

  # MAC 的に自分宛でなくても受信できるようにする
  def self.set_promisc(ifindex, sock)
    sock.setsockopt(Nwdiy::SOL_PACKET, Nwdiy::PACKET_ADD_MEMBERSHIP, 
                    [ifindex, Nwdiy::PACKET_MR_PROMISC].pack("I!S!x10"))
  end

  # パケットが来たので転送する
  def self.recv_data(sock)
    ifname = @@name[sock.fileno]
    debug("recv from #{ifname} (#{sock})")
    begin
      pkt = sock.sysread(65536)
      debug("recv #{pkt.bytesize} bytes")
    rescue EOFError
      @@peer[ifname].delete(sock)
      @@name[sock.fileno] = nil
      if @@peer[ifname].length == 0
        os = @@os.delete(ifname)
        if os
          os.close
        end
      end
      return
    end
    dest = @@peer[ifname] + [@@os[ifname]]
    dest.compact!
    debug("from #{sock} to #{dest}")
    dest.each do |peer|
      next if peer == sock
      debug("send to #{peer}")
      peer.syswrite(pkt)
    end
  end

  def self.stop_daemon
    @@thread.kill.join if @@thread
  end
end
