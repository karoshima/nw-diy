#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require_relative '../../nwdiy'

require 'nwdiy/util'
require 'nwdiy/packet/uint16'
require 'nwdiy/packet/mac'

class NWDIY
  class PKT

    autoload(:IPv4, 'nwdiy/packet/ipv4')
    autoload(:ARP,  'nwdiy/packet/ipv4')
    autoload(:IPv6, 'nwdiy/packet/ipv6')
    autoload(:VLAN, 'nwdiy/packet/vlan')

    class Ethernet

      ################################################################
      # パケット生成
      ################################################################
      # 受信データあるいはハッシュデータからパケットを作る
      def initialize(pkt = nil)
        if (pkt.kind_of?(String) && pkt.bytesize > 14)
          self.dst = pkt[0..5]
          self.src = pkt[6..11]
          self.type = pkt[12..13]
          pkt[0..13] = ''
          self.data = pkt
        elsif pkt.kind_of?(Hash)
          self.dst = pkt[:dst]
          self.src  = pkt[:src]
          pkt[:type] and self.type = pkt[:type]
          pkt[:data] and self.data = pkt[:data]
        else
          self.dst = nil
          self.src = nil
        end
      end

      ################################################################
      # 宛先 MAC
      def dst=(mac)
        @dst = NWDIY::PKT::MAC.new(mac)
      end
      def dst
        @dst
      end

      ################################################################
      # 送信先 MAC
      def src=(mac)
        @src = NWDIY::PKT::MAC.new(mac)
      end
      def src
        @src
      end

      ################################################################
      # Ethernet の type あるいは IEEE802.3 の length
      def type=(ethertype)
        tmp = NWDIY::PKT::Ethernet::Type.new(ethertype)
        if tmp > 1500
          @type = tmp
          # self.data = XXX 新しい型に合わせて読み直す
        else
          @type = nil
        end
      end
      def type
        @type and return @type
        # ↑ Ethernet
        # ↓ 802.3
        NWDIY::PKT::Ethernet::Type.new(@data ?
                                       @data.length :
                                       0).to_i
      end
      class Type < NWDIY::PKT::UINT16
        TYPES = {
          'IPv4' => 0x0800,
          'ARP'  => 0x0806,
          'IPv6' => 0x86dd,
          'VLAN' => 0x8100 }

        # TYPES に定義した固定文字列か、あるいは数値かバイナリ
        def initialize(val)
          super(TYPES[val] || val)
        end

        # 値ならデータの型を返す
        # (autoload が効くように、配列やハッシュにせずコードで列挙する)
        def klass
          case self
          when 0x0800 then NWDIY::PKT::IPv4
          when 0x0806 then NWDIY::PKT::ARP
          when 0x86dd then NWDIY::PKT::IPv6
          when 0x8100 then NWDIY::PKT::VLAN
          else             NWDIY::PKT::Binary
          end
        end
      end

      ################################################################
      # データ部
      def data=(body)
        # XXX @type があれば、そこから型を求める
        @data = NWDIY::PKT::Binary.new(body)
      end
      def data
        @data
      end

      def length
        14 + @data.length
      end

      def to_s
        '[Ethernet dst=' + @dst.to_s + ', src=' + @src.to_s + ', type=' + self.type.to_s + ', data=' + @data.to_s + ']'
      end

      def to_pkt
        self.dst.to_pkt + self.src.to_pkt + self.type.to_pkt + self.data.to_pkt
      end

    end
  end
end
