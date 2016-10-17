#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# ruby で綴る、デーモン (root権限持ち) に頼った VM interface

require_relative '../../nwdiy'

require 'nwdiy/util'

module NwDiy
  class Interface
    class Proxy
      include NwDiy::Linux

      def initialize(klass, name)
        begin
          @sock = UNIXSocket.new(DAEMON_SOCKFILE)
        rescue Errno::ENOENT, Errno::ECONNREFUSED => e
          raise e.class.new('Please run NW-DIY daemon')
        end
        @klass = klass
        Marshal.dump({klass: klass, name: name}, @sock)
      end

      ################
      # socket op
      def recv
        @klass.packet.new(Marshal.load(@sock))
      end
      def send(pkt)
        Marshal.dump(pkt, @sock)
        pkt.bytesize
      end
      def recvq_empty?
        IO.select([@sock], [], [], 0)
      end
    end
  end
end
