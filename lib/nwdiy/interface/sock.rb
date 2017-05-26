#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# ruby で綴る、デーモン (インターフェースサーバー) に頼った VM interface

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
        self.class.send_sock(sock, name)
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
      def recv_ready?
        @sock.ready?
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
              begin
                newifp = ifp.accept
                newifp.autoclose = true
                name = NwDiy::Interface::Sock.recv_sock(newifp)
                @name2ifp[name] << newifp
                @ifp2name[newifp.fileno] = name
                if NwDiy::Interface.debug[:packet]
                  puts "SockServer: #{name}: new client"
                end
              rescue Errno::EAGAIN, Errno::EINTR => e
                # retry
              end
            else
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
