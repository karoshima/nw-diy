#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
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

    class VLAN
      include Packet
      include NwDiy::Linux

      ################################################################
      # プロトコル番号とプロトコルクラスの対応表
      @@kt = KlassType.new({ VLAN => 0x8100,
                             ARP  => 0x0806,
                             IPv4 => 0x0800,
                             IPv6 => 0x86dd,
                             QinQ => 0x88a8 })

      ################################################################
      # パケット生成
      ################################################################
      # 受信データあるいはハッシュデータからパケットを作る
      def initialize(pkt = nil)
        super()
        case pkt
        when String
          pkt.bytesize > 4 or
            raise TooShort.new("VLAN", 4, pkt)
          @tci = pkt[0..1].btoh
          @type = pkt[2..3].btoh
          pkt[0..3] = ''
          self.data = pkt
        when nil
          @tci = nil
          @type = nil
          @data = Binary.new('')
        else
          raise InvalidData.new "What is '#{pkt}'?"
        end
      end

      ################################################################
      # 各フィールドの値
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

    end
  end
end
