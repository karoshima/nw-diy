#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# ruby で綴る、デーモン (インターフェースサーバー) に頼った VM interface
#
#    パケットを送受信するインターフェースです。
#    と言いつつ実インターフェースは使いません。
#    NW-DIY 同士で使える仮想インターフェースを作って、それを使います。
#
# インターフェース作成方法
# 
#  ifp = NwDiy::Interface.new(OS に実在しないインターフェースの名称)
#    ソケットによる仮想的なインターフェースでイーサネットフレームを
#    送受信するためのインターフェースインスタンスを作成します。
#
#  ifp = NwDIy::Interface.new(下記のハッシュ)
#                             name: インターフェースの名称
#                             type: :sock
#    同上
#
# 使いかた
#
#  ifp.recv
#    インターフェースでイーサネットフレームをひとつ受信して返します。
#    フレームが届いていなければ、届くまで待ちます。
#
#  ifp.ready?
#    インターフェースにイーサネットフレームが来ているかどうか返します。
# 
#  ifp.send
#    インターフェースからイーサネットフレームをひとつ送信します
#
################################################################

require_relative '../../nwdiy'

require 'io/wait'
require 'nwdiy/packet/ethernet'

module NwDiy
  class Interface
    class Sock
      include NwDiy::Linux

      SOCKPORT = 43218
      def self.send_sock(sock, data)
        bytesize = data.bytesize
        marshal = Marshal.dump(data)
        sock << [marshal.bytesize].pack("N") + marshal
        bytesize
      end
      def self.recv_sock(sock)
        len = sock.read(4)
        raise EOFError unless len
        buflen, = len.unpack("N")
        buf = sock.read(buflen)
        raise EOFError unless buf
        Marshal.load(buf)
      end

      # インターフェースサーバーに接続する
      def initSock(name)
        @name = name
        begin
          # 既に誰かがサーバーやってくれてたら、そこを使う
          sock = TCPSocket.open('::1', SOCKPORT)
          sock.autoclose = true
        rescue Errno::ECONNREFUSED
          # 誰もサーバーやってくれてなかったら、自分でサーバーやる
          begin
            self.startServer
          rescue Errno::EADDRINUSE
            sleep 0.1
          end
          retry
        end

        # インターフェース名をサーバーに登録して ack を貰う
        self.class.send_sock(sock, name)
        NwDiy::Interface::Sock.recv_sock(sock)

        # sock をインスタンスに登録する
        @sock.close if @sock
        @sock = sock
      end

      ################
      # インターフェースを作る
      def initialize(name)
        @sock = self.initSock(name)
      end

      ################
      # socket op
      def recv
        begin
          self.class.recv_sock(@sock)
        rescue EOFError, Errno::ECONNRESET
          self.initSock(@name)
          retry
        end
      end
      def send(pkt)
        self.class.send_sock(@sock, pkt)
      end
      def recv_ready?(timeout=0)
        !!@sock.wait_readable(timeout)
      end

      # サーバーを起動する
      def startServer
        @@server = NwDiy::Interface::SockServer.new(SOCKPORT)
        Thread.new { @@server.run }
        puts 'Started'
      end

      ################
      # interface address
      def to_s
        @name
      end

    end

    class SockServer

      def initialize(port)
        @listen = TCPServer.new('::1', port)
        @listen.autoclose = true
        @listen.setsockopt(:SOCKET, :REUSEADDR, true)
        @name2ifp = Hash.new { |h,k| h[k] = Array.new }
        @ifp2name = Hash.new
      end

      def run
        Thread.abort_on_exception = true
        loop do
          recv, = IO.select([@listen] + @name2ifp.values.flatten)
          recv.each do |ifp|
            next unless ifp.ready?

            if (ifp == @listen)
              # 新規インターフェースが申告されたら
              # デーモンインスタンスに登録したうえで
              # ack を返す
              begin
                newifp = ifp.accept
                newifp.autoclose = true
                name = NwDiy::Interface::Sock.recv_sock(newifp)
                @name2ifp[name] << newifp
                @ifp2name[newifp.fileno] = name
                if NwDiy::Interface.debug[:packet]
                  puts "SockServer: #{name}: new client"
                end
                NwDiy::Interface::Sock.send_sock(newifp, name)
              rescue Errno::EAGAIN, Errno::EINTR => e
                # retry
              end

            else
              # 登録されたインターフェースからパケットが送出されたら
              # 同じ名称のインターフェースに届ける
              name = @ifp2name[ifp.fileno]
              if NwDiy::Interface.debug[:packet]
                puts "SockServer: #{name}: #{Thread.current}"
              end
              begin
                pkt = NwDiy::Interface::Sock.recv_sock(ifp)
                if NwDiy::Interface.debug[:packet]
                  puts "    new Packet arrives"
                end
                selected = IO.select([], @name2ifp[name] - [ifp], [], 0)
                if selected
                  selected[1].each do |dstifp|
                    NwDiy::Interface::Sock.send_sock(dstifp, pkt)
                    if NwDiy::Interface.debug[:packet]
                      puts "SockServer: #{@ifp2name[dstifp.fileno]}: sent"
                    end
                  end
                else
                  if NwDiy::Interface.debug[:packet]
                    puts "    WARNING: a packet is sent to monopole ethernet."
                  end
                end
              rescue EOFError
                if NwDiy::Interface.debug[:packet]
                  puts "    destroyed client"
                end
                name = @ifp2name.delete(ifp.fileno)
                @name2ifp[name].delete(ifp)
                ifp.close
              end
            end
          end
        end
      end
    end

  end
end
