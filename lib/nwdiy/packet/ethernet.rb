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
      # プロトコル番号とプロトコルクラスの対応表
      # (遅延初期化することで、使わないクラス配下のデータクラスまで
      #  無駄に読み込んでしまうことを防ぐ)
      @@class2id = nil
      def self.class2id(arg = nil)
        arg === Class or arg = arg.class
        unless @@class2id
          @@class2id = Hash.new
          @@class2id[VLAN] = 0x8100
          @@class2id[ARP]  = 0x0806
          @@class2id[IPv4] = 0x0800
#          @@class2id[IPv6] = 0x86dd
        end
        @@class2id[arg]
      end
      @@id2class = nil
      def self.id2class(type)
        type or return Binary
        unless @@id2class
          @@id2class = Array.new
          @@class2id or self.class2id
          @@class2id.each {|cl,id| @@id2class[id] = cl}
        end
        @@id2class[type] || Binary
      end

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
        dtype = self.class.class2id(val)
        if dtype
          @type = dtype
          @data = val
          return
        end
        klass = self.class.id2class(@type)
        begin
          @data = klass.new(val)
        rescue => e
          raise e.class.new("#{klass}:#{e.message}")
        end
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
