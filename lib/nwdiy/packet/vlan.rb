#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
#
# vlan パケットの処理
#
# vlan = NwDiy::Packet::VLAN.new
#    初期化された VLAN パケットを作成します。
#
# vlan = NwDiy::Packet::VLAN.new(バイナリデータ)
#    バイナリデータをパケットデータとして読み込み、
#    VLAN パケットを作成します。
#
# vlan.pcp, vlan.cfi
#    VLAN パケットの各フィールドを読み書きします。
#
# vlan.vid
#    VLAN パケットの vlan-id を読み書きします
#
# vlan.data
#    VLAN パケットのデータ部を読み書きします。
# 
# vlan.bytesize
#    IPv6 パケットのバイト長を返します
# 
# vlan.to_pkt
#    IPv6 パケットのバイナリデータ化します
#
# vlan.to_s
#    IPv6 パケットをを可読化します
#
################################################################

require_relative '../../nwdiy'

require 'nwdiy/util'
require 'nwdiy/packet'

module NwDiy
  module Packet

    autoload(:IPv4, 'nwdiy/packet/ipv4')
    autoload(:ARP,  'nwdiy/packet/arp')
    autoload(:IPv6, 'nwdiy/packet/ipv6')
    autoload(:VLAN, 'nwdiy/packet/vlan')
    autoload(:QinQ, 'nwdiy/packet/qinq')

    class VLAN < NwDiy::Packet::Ethernet

      ################################################################
      # パケット生成
      ################################################################
      # 受信データあるいはハッシュデータからパケットを作る
      def initialize(pkt = nil)
        super()
        case pkt
        when String
          raise TooShort.new("VLAN", 4, pkt) unless pkt.bytesize > 4
          @tci = pkt[0..1].btoh
          @type = pkt[2..3].btoh
          pkt[0..3] = ''
          self.data = pkt
        when nil
          @tci = 0
        else
          raise InvalidData.new "What is '#{pkt}'?"
        end
      end

      ################################################################
      # 各フィールドの値
      #    tci, pcp, cfi, vid は vlan 独自
      #    type, data は NwDiy::Packet::Ethernet のものを使う
      #    NwDiy::Packet::Ethernet の src,dst は使わない
      ################################################################

      attr_accessor :tci

      def pcp=(val)
        @tci = ((val << 13) & 0xe000) | (@tci & 0x1fff)
      end
      def pcp
        (@tci & 0xe000) >> 13
      end

      def cfi=(val)
        if val
          @tci |=  0x1000
        else
          @tci &=~ 0x1000
        end
      end
      def cfi
        (@tci & 0x1000) == 0x1000
      end

      def vid=(val)
        @tci = (@tci & 0xf000) | (val & 0x0fff)
      end
      def vid
        @tci & 0x0fff
      end

      def data=(val)
        ktype = @@kt.type(val)
        if ktype == 0
          @data = @@kt.class(@type).new(val)
        else
          @type = ktype
          @data = val
        end
      end
      attr_reader :data

      ################################################################
      # その他の諸々
      def to_pkt
        @tci.htob16 + self.type.htob16 + @data.to_pkt
      end
      def bytesize
        4 + @data.bytesize
      end
      def to_s
        name = resolv('/etc/ethertypes', self.type4)
        if name.kind_of?(Array)
          name = name[0]
        end
        "[VLAN#{self.vid} #@data]"
      end

    end
  end
end
