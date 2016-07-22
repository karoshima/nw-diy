#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# ruby で綴る VM interface のための、root 権限持ちデーモン

require_relative '../lib/nwdiy'

require 'nwdiy/interface'

module NwDiy
  class Interface

    ################
    # NWDIY の VM インターフェースからの接続を待つデーモン
    class ProxyDaemon
      include NwDiy::Linux

      def initialize(argv)
        Thread.abort_on_exception = true
        File.umask(0)
        @debug = argv.grep('-d').size > 0
      end

      def debug(*arg)
        @debug and puts arg
      end

      # NWDIY アプリからの接続を待ち受けて
      # ProxyClient でスレッド処理する
      def run
        self.debug("Start #{$0} (pid=#{Process.pid})")
        begin
          @sock = UNIXServer.new(DAEMON_SOCKFILE)
        rescue Errno::EADDRINUSE => e
          begin
            UNIXSocket.new(DAEMON_SOCKFILE)
            raise e
          rescue Errno::ECONNREFUSED
            File.unlink(DAEMON_SOCKFILE)
            @sock = UNIXServer.new(DAEMON_SOCKFILE)
          end
        end
        begin
          count = 0
          while accept = @sock.accept
            count += 1
            Bypass.new(self, accept, count).start
          end
        rescue SignalException
        ensure
          self.debug("Finish #{$0} (pid=#{Process.pid})")
          File.unlink(DAEMON_SOCKFILE)
        end
      end
    end

    ################
    # デバイスと NWDIY クライアントとの橋渡し
    class Bypass

      def initialize(daemon, sock, id)
        @daemon = daemon
        @cli = sock
        @id = id
        begin
          data = Marshal.load(@cli)
        rescue EOFError
          return
        end
        @klass = data[:klass]
        @name = data[:name]
        begin
          @dev = @klass.new(@name)
        rescue Errno::EPERM
          raise Errno::EPERM.new("run #{$0} as a super user!!!")
        end
        @daemon.debug("Client[#{@id}] opens #{@klass}(#{@name})")
      end
      def start
        @dev2cli = Thread.new { self.dev2cli }
        @cli2dev = Thread.new { self.cli2dev }
      end

      def dev2cli
        while pkt = @dev.recv_raw
          Marshal.dump(pkt, @cli)
        end
      rescue Errno::ECONNRESET
        @daemon.debug("Client[#{@id}] closes #{@klass}(#{@name})")
      ensure
        @cli2dev.kill
      end

      def cli2dev
        while pkt = Marshal.load(@cli)
          @dev.send(pkt)
        end
      rescue Errno::ECONNRESET, EOFError
        @daemon.debug("Client[#{@id}] closes #{@klass}(#{@name})")
      ensure
        @dev2cli.kill
      end

    end
  end
end

if $0 == __FILE__
  NwDiy::Interface::ProxyDaemon.new(ARGV).run
end
