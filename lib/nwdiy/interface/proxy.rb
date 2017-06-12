#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# ruby で綴る、デーモン (root権限持ち) に頼った VM interface
#
# インターフェース作成方法
# 
#  ifp = NwDiy::Interface.new(OS に実在するインターフェースの名称)
#    OS に実在するインターフェースでイーサネットフレームを
#    送受信するためのインターフェースインスタンスを作成したくても
#    その権限がないときに、util/interface_daemon.rb に送受信を
#    委託するためのインターフェースインスタンスを作成します。
#    事前に util/interface_daemon.rb が起動されている必要があります。
#
#  ifp = NwDIy::Interface.new(下記のハッシュ)
#                             name: OS に実在するインターフェースの名称
#                             type: :pcap
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
      def recv_ready?
        @sock.ready?
      end
    end
  end
end
