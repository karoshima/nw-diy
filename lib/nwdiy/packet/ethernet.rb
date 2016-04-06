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
          @data = pkt
          self.compile
        when nil
        else
          raise InvalidData.new(pkt)
        end
      end

      ################################################################
      # 各フィールドの値
      ################################################################

      attr_accessor :data
      attr_reader :dst, :src, :type

      def dst=(val)
        @dst = MacAddr.new(val)
      end
      def src=(val)
        @src = MacAddr.new(val)
      end

      def type=(val)
        case val
        when String
          if val.bytesize == 2
            @type = val.btoh
          else
            @type = resolv('/etc/ethertypes', val)
            @type or
              raise InvaliData.new(val)
            @type = @type.to_i(16)
          end
        when Integer, nil
          @type = val
        else
          raise InvaliData.new(val)
        end
      end
      def type4
        sprintf("%04x", @type)
      end

      ################################################################
      # 設定されたデータを元に、設定されてないデータを補完する
      def compile(overwrite=false)
        @dst or @dst = MacAddr.new("\0\0\0\0\0\0")
        @src or @src = MacAddr.new("\0\0\0\0\0\0")

        # autoload で不要なモジュールの読み込みを防ぐため
        # @type と @data 型の関係は構造化せず case 処理する
        case @data
        when VLAN then klass = 0x8100
        when ARP  then klass = 0x0806
        when IPv4 then klass = 0x0800
        when IPv6 then klass = 0x86dd
        else           klass = nil
        end
        if klass
          if klass != @type
            if !@type or overwrite
              @type = klass
            else
              raise InvalidData.new(sprintf("type:0x%04x != data:%s", @type, @data.class))
            end
          end
        else
          case @type
          when 0x8100 then @data = VLAN.new(@data).compile
          when 0x0806 then @data = ARP.new(@data).compile
          when 0x0800 then @data = IPv4.new(@data).compile
#          when 0x86dd then @data = IPv6.new(@data).compile
          else
            @data = Binary.create(@data)
            (@type && @type > 1500) or
              @type = 14 + @data.bytesize
          end
        end
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
