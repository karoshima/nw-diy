#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require_relative '../../nwdiy'

require 'nwdiy/util'
require 'nwdiy/macaddr'

class NWDIY
  class PKT

    autoload(:IPv4,    'nwdiy/packet/ipv4')
    autoload(:ARP,     'nwdiy/packet/ipv4')
    autoload(:IPv6,    'nwdiy/packet/ipv6')
    autoload(:VLAN,    'nwdiy/packet/vlan')

    class Ethernet
      include NWDIY::Linux

      ################################################################
      # パケット生成
      ################################################################
      # 受信データあるいはハッシュデータからパケットを作る
      def initialize(pkt = nil)
        case pkt
        when String
          pkt.bytesize > 14 or
            raise TooShort.new(pkt)
          @dst = MacAddr.new(pkt[0..5])
          @src = MacAddr.new(pkt[6..11])
          self.type = pkt[12..13]
          pkt[0..13] = ''
          self.data = pkt
          self.compile
        when nil
        else
          raise InvalidData.new(pkt)
        end
      end

      ################################################################
      # 各フィールドの値
      ################################################################

      attr_reader :dst, :src, :type, :data

      def dst=(val)
        @dst = MacAddr.new(val)
      end
      def src=(val)
        @src = MacAddr.new(val)
      end

      def type=(val)
        # 代入されたら @data も変わる
        case val
        when String
          if val.bytesize == 2
            @type = val.btoh
          else
            res = resolv('/etc/ethertypes', val)
            res or
              raise InvalidData.new("unknown ether type: #{val}")
            @type = res.to_i(16)
          end
        when Integer, nil
          @type = val
        else
          raise InvalidData.new("unknown ether type: #{val}")
        end
        self.data = @data
      end
      def type4
        sprintf("%04x", @type)
      end

      def data=(val)
        # 代入されたら @type の値も変わる
        # 逆に val の型が不明なら、@type に沿って @data の型が変わる
        case val
        when VLAN then @type = 0x8100
        when ARP  then @type = 0x0806
        when IPv4 then @type = 0x0800
        when IPv6 then @type = 0x86dd
        else
          case @type
          when 0x8100 then val = VLAN.cast(val)
          when 0x0806 then val = ARP.cast(val)
          when 0x0800 then val = IPv4.cast(val)
#          when 0x86dd then val = IPv6.cast(val)
          else             val = Binary.cast(val)
          end
        end
        @data = val
      end

      ################################################################
      # 設定されたデータを元に、設定されてないデータを補完する
      def compile(overwrite=false)
        @dst or @dst = MacAddr.new("\0\0\0\0\0\0")
        @src or @src = MacAddr.new("\0\0\0\0\0\0")

        @data or
          raise InvalidData.new('Ether data is necessary')
        (!@type || @type <= 1500) and
          @type = 14 + @data.bytesize
        self
      end

      ################################################################
      # その他の諸々
      def to_pkt
        self.compile
        @dst.hton + @src.hton + @type.htob16 + @data.to_pkt
      end
      def bytesize
        14 + @data.bytesize
      end
      def to_s
        self.compile
        "[Ethernet #@dst > #@src #{self.type4} #@data]"
      end

    end
  end
end
