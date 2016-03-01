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
      # 各フィールドの値の操作
      ################################################################
      # 宛先 MAC
      def dst=(mac)
        @dst = NWDIY::PKT::MAC.new(mac)
      end
      def dst
        @dst
      end

      ################
      # 送信先 MAC
      def src=(mac)
        @src = NWDIY::PKT::MAC.new(mac)
      end
      def src
        @src
      end

      ################
      # Ethernet の type あるいは IEEE802.3 の length
      TYPES = {
        'IPv4' => 0x0800,
        'ARP'  => 0x0806,
        'IPv6' => 0x86dd,
        'VLAN' => 0x8100 }
      def type=(val)
        val = TYPES[val] || val
        val = NWDIY::PKT::UINT16.new(val)
        if val > 1500
          @type = val
        else
          @type = nil
        end
        # 型が変わるなら、フォーマット適用し直し
        (@data && @data.class != self.dataKlass) and
          self.data = @data.to_pkt
      end
      def type
        # Ethernet       802.3
        # ↓              ↓
        @type || (@data ? @data.length : 0)
      end

      ################
      # データ部
      def dataKlass
        # (autoload が効くように、配列やハッシュにせずコードで列挙する)
        case @type
        when 0x0806 then NWDIY::PKT::ARP
        # when 0x0800 then NWDIY::PKT::IPv4
        # when 0x86dd then NWDIY::PKT::IPv6
        # when 0x8100 then NWDIY::PKT::VLAN
        else             NWDIY::PKT::Binary
        end
      end
      def data=(body)
        @data = self.dataKlass.new(body)
      end
      def data
        @data
      end

      ################################################################
      # その他の諸々
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
