#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# ruby で綴る、AF_PACKET による VM interface
#
# インターフェース作成方法
# 
#  ifp = NwDiy::Interface.new(OS に実在するインターフェースの名称)
#    OS に実在するインターフェースでイーサネットフレームを
#    送受信するためのインターフェースインスタンスを作成します。
#    ただしインターフェースからパケット送受信する権限がないときには
#    util/interface_daemon.rb に送受信を委託します。
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
require 'nwdiy/interface/iplink'
require 'nwdiy/packet'

module NwDiy
  class Interface
    class Pcap
      include NwDiy::Linux

      # /usr/include/linux/if_arp.h
      ARPHRD_LOOPBACK = 772

      # /usr/incluce/netpacket/packet.h
      PACKET_OUTGOING = 4

      def self.packet
        NwDiy::Packet::Ethernet
      end

      def initialize(name)
        @index, @name = NwDiy::Interface::IpLink.ifindexname(name)
        @sock = Socket.new(PF_PACKET, SOCK_RAW, ETH_P_ALL.htons)
        @sock.bind(pack_sockaddr_ll(@index))
        self.clean
        self.set_promisc
      end

      ################
      # open 後 bind 前に受信してしまったパケットを
      # 掃除する
      def clean
        buf = ''
        loop do
          begin
            @sock.read_nonblock(1, buf)
          rescue Errno::EAGAIN, Errno::EWOULDBLOCK
            return # DONE
          rescue Errno::EINTR
            # retry
          end
        end
      end

      ################
      # promisc モード on
      def set_promisc
        opt = PACKET_ADD_MEMBERSHIP
        mreq = [@index, PACKET_MR_PROMISC].pack("I!S!x10")
        @sock.setsockopt(SOL_PACKET, opt, mreq)
      end

      ################
      # socket op
      def recv
        self.class.packet.new(self.recv_raw)
      end
      def recv_raw
        loop do
          pkt, ll = @sock.recvfrom(65540)
          redo if
            (ll.hatype == ARPHRD_LOOPBACK && ll.pkttype == PACKET_OUTGOING)
          return pkt
        end
      end
      def send(pkt)
        if pkt.src.to_s == '00:00:00:00:00:00'
          pkt.src = self.mac
        end
        if pkt.respond_to?(:to_pkt)
          pkt = pkt.to_pkt
        end
        @sock.send(pkt, 0)
      end
      def close
        @sock.close
      end
      def recv_ready?(timeout=0)
        !!@sock.wait_readable(timeout)
      end

      ################
      # 自分の MAC アドレスを調べる
      def mac
        unless @mac
          @mac = NwDiy::Interface::IpLink.new[@index].mac
        end
        @mac
      end

      ################
      # interface address
      def to_s
        @name
      end
    end
  end
end
