#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# ruby で綴る、デーモン (インターフェースサーバー) に頼った VM interface

require_relative '../../nwdiy'

require 'nwdiy/packet/ethernet'

module NwDiy
  class Interface
    class Sock
      include NwDiy::Linux

      SOCKPORT = 43218

      # インターフェースサーバーに接続する
      def initSock(name)
        @name = name
        begin
          # 既に誰かがサーバーやってくれてたら、そこを使う
          sock = TCPSocket.open('::1', SOCKPORT)
        rescue Errno::ECONNREFUSED
          # 誰もサーバーやってくれてなかったら、自分でサーバーやる
          begin
            self.startServer
          rescue Errno::EADDRINUSE
            sleep 0.1
          end
          retry
        end
        Marshal.dump(name, sock)
        @sock and @sock.close
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
          Marshal.load(@sock)
        rescue EOFError
          self.initSock(@name)
          retry
        end
      end

      def send(pkt)
        Marshal.dump(pkt, @sock)
        pkt.bytesize
      end

      # サーバーを起動する
      def startServer
        @@server = NwDiy::Interface::SockServer.new(SOCKPORT)
        Thread.new { @@server.run }
        puts 'Started'
      end

    end

    class SockServer

      def initialize(port)
        @listen = TCPServer.new('::1', port)
        @listen.setsockopt(:SOCKET, :REUSEADDR, true)
        @name2ifp = Hash.new { |h,k| h[k] = Array.new }
        @ifp2name = Hash.new
      end

      def run
        Thread.abort_on_exception = true
        loop do
          recv, = IO.select(@name2ifp.values.inject([@listen]) {|a,b| a+=b})
          recv.each do |ifp|
            if (ifp == @listen)
              begin
                newifp = ifp.accept
                name = Marshal.load(newifp)
                @name2ifp[name] << newifp
                @ifp2name[newifp.peeraddr[1]] = name
              rescue Errno::EAGAIN, Errno::EINTR => e
                # retry
              end
            else
              name = @ifp2name[ifp.peeraddr[1]]
              begin
                pkt = Marshal.load(ifp)
                (@name2ifp[name] - [ifp]).each do |dstifp|
                  Marshal.dump(pkt, dstifp)
                end
              rescue EOFError
                name = @ifp2name.delete(ifp.peeraddr[1])
                @name2ifp[name].delete(ifp)
              end
            end
          end
        end
      end
    end

  end
end
