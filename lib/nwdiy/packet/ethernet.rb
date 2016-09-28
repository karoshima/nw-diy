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
require 'nwdiy/packet/macaddr'

module NwDiy
  module Packet

    autoload(:IPv4, 'nwdiy/packet/ipv4')
    autoload(:ARP,  'nwdiy/packet/arp')
    autoload(:IPv6, 'nwdiy/packet/ipv6')
    autoload(:VLAN, 'nwdiy/packet/vlan')

    class Ethernet
      include Packet
      include NwDiy::Linux

      ################################################################
      # プロトコル番号とプロトコルクラスの対応表
      @@kt = KlassType.new({ VLAN => 0x8100,
                             ARP  => 0x0806,
                             IPv4 => 0x0800,
                             IPv6 => 0x86dd })

      ################################################################
      # パケット生成
      ################################################################
      # 受信データあるいはハッシュデータからパケットを作る
      def initialize(pkt = nil)
        super()
        case pkt
        when String
          pkt.bytesize > 14 or
            raise TooShort.new(pkt)
          @dst = MacAddr.new(pkt[0..5])
          @src = MacAddr.new(pkt[6..11])
          @type = pkt[12..13].btoh
          pkt[0..13] = ''
          self.data = pkt
        when nil
          @dst = MacAddr.new("\0\0\0\0\0\0")
          @src = MacAddr.new("\0\0\0\0\0\0")
          @type = nil
          @data = Binary.new('')
        else
          raise InvalidData.new(pkt)
        end
      end

      ################################################################
      # 各フィールドの値
      ################################################################

      def dst=(val)
        @dst = MacAddr.new(val)
      end
      attr_reader :dst

      def src=(val)
        @src = MacAddr.new(val)
      end
      attr_reader :src

      attr_writer :type
      def type
        if @auto_compile
          val = @@kt.type(@data, @type)
          val == 0 and
            val = 14 + @data.bytesize
          val
        else
          @type
        end
      end
      def type4
        sprintf("%04x", self.type)
      end
      alias length type

      def data=(val)
        @data = val.kind_of?(Packet) ? val : Binary.new(val)
      end
      def data
        (@auto_compile && @data.kind_of?(Binary) && @@kt.klass(@type) != Binary) and
          @data = @@kt.klass(@type).new(@data)
        @data
      end

      ################################################################
      # @auto_compile 設定
      def auto_compile=(bool)

        # 解除するまえに、これまでの正常値を設定しておく
        unless bool
          @type = self.type
        end

        # 値を反映して、データ部にも伝える
        @auto_compile = bool
        @data.respond_to?(:auto_compile=) and
          @data.auto_compile = bool
      end

      ################################################################
      # その他の諸々
      def to_pkt
        @dst.hton + @src.hton + self.type.htob16 + @data.to_pkt
      end
      def bytesize
        14 + @data.bytesize
      end
      def to_s
        name = resolv('/etc/ethertypes', self.type4)
        name.kind_of?(Array) and
          name = name[0]
        "[Ethernet #@src > #@dst #{name} #@data]"
      end

    end
  end
end
