#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2017 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# ruby で綴る L2 Host
#
#    MAC アドレスの付与されたインターフェースで
#    パケットの送受信を行ないます。
#
#    Ethernet インターフェースに届いたパケットのうち下記について、
#    Ethernet ヘッダを剥がして受信します。
#    - 自局 MAC アドレス宛
#    - Broadcast/Multicast アドレス宛
#
#    送信する L3 プロトコルパケットには、
#    適切な Ethernet ヘッダを付与してから送信します。
#
# インスタンス作成方法
#
#  l2host = NwDiy::L2Host.new(interface = nil, mac = nil)
#    L2 ホストを作成します
#    引数にインターフェースと MAC アドレスを指定できます。
#    インターフェースを割り当てたとき、mac を略すと
#    なんかテキトーな MAC アドレスを割り当てます。
#
#  l2host.interface
#    Ethernet インターフェースを返します。
#    代入も可能です。
#
#  l2host.addr
#    L2 ホストが持つ MAC addr を返します。
#    代入も可能です。
#
#  l3pkt = l2host.recv
#    自分宛, ブロードキャスト, マルチキャストパケットのパケットを受信し
#    Ethernet ヘッダを削除して返します。
#    このとき l3pkt には recv_pkttype が設定されます。
#    (詳細は NwDiy::Packet.recv_pkttype 参照)
#
#  l2host.send(l3pkt, dstmac = nil)
#    L3 パケットに Ethernet ヘッダを付けて送信します。
#    送信元 MAC はインターフェース固有のものになります。
#    宛先 MAC は引数に指定されたものを使いますが、
#    指定のない場合には L3 プロトコル毎の仕組みを使って調べます。
#
################################################################

require_relative '../../nwdiy'

require 'nwdiy/vm'

module NwDiy
  class L2Host < NwDiy::VM

    def initialize(interface = nil, mac = nil)
      super(interface)
      if interface
        if mac.kind_of?(NwDiy::Packet::MacAddr)
          interface.local = mac
        else
          interface.local = NwDiy::Packet::MacAddr.new(:global)
        end
      end
    end

    def interface
      self.iflist[0]
    end
    def interface=(ifp)
      old = self.interface
      self.addif(ifp)
      self.delif(old)
    end

    def addr=(mac)
      self.interface.local = mac
    end
    def addr
      mac = self.interface.local
      unless mac
        mac = self.interface.local = NwDiy::Packet::MacAddr.new(:global)
      end
    end

    def recv
      loop do
        ifp, pkt = super
        next unless pkt.kind_of?(NwDiy::Packet::Ethernet)
        if pkt.dst.broadcast?
          pkt.recv_pkttype = NwDiy::Packet::PACKET_BROADCAST
          break
        end
        if pkt.dst.multicast?
          pkt.recv_pkttype = NwDiy::Packet::PACKET_MULTICAST
          break
        end
        if pkt.dst == self.interface.local
          pkt.recv_pkttype = NwDiy::Packet::PACKET_HOST
          break;
        end
      end
      pkt
    end

    def send(pkt, dst = nil)
      if dst == nil
        raise "ARP/NDP are NOT IMPLEMENTED YET (;_;)"
        # ARP/NDP 解決処理を入れる
        # あるいは pkt 種別 (class) によっては自動で決まる場合もある
      end
      eth = NwDiy::Packet::Ethernet.new
      eth.src = self.interface.local
      eth.dst = dst
      eth.data = pkt
      self.interface.send(pkt)
    end

  end
end
