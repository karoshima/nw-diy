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
            raise TooShort.new("Ethernet", 14, pkt)
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
          raise InvalidData.new "What is '#{pkt}'?"
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

      def ethernet?
        @type && 1500 < @type
      end
      def ieee802dot3?
        @type && 46 <= @type && @type <= 1500
      end
      def type=(val)
        self.ieee802dot3? and
          raise InvalidData.new "This 802.3 frame is unavailable to turn into a Ethernet."
        (1500 < val) or
          raise InvalidData.new "Ethernet type must be greater than 1500."
        oldtype = @type
        @type = val
        @data and
          begin
            self.data = @data.to_pkt
          rescue => e
            @type = oldtype
            raise e
          end
        @type
      end
      def length=(val)
        self.ethernet? and
          raise InvalidData.new "This Ethernet frame is unavailable to turn into 802.3 frame."
        (1500 < val) and
          raise InvalidData.new "802.3 length must be less than 1501"
        @type = val
      end
      attr_reader :type
      alias length type
      def type4
        @type.to_s(16).rjust(4, "0")
      end

      def data=(val)
        if self.ieee802dot3?
          @data = val.kind_if?(Packet) ? val : Binary.new(val)
        else
          ktype = @@kt.type(val)
          if ktype == 0
            @data = @@kt.klass(@type).new(val)
          else
            @type = ktype
            @data = val
          end
        end
        @data
      end
      attr_reader :data

      ################################################################
      # @auto_compile 設定
      def auto_compile=(bool)

        # 解除するまえに、これまでの正常値を設定しておく
        #unless bool
        #end

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
