#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require 'ipaddr'

module NwDiy
  module Packet

    module IP
      autoload(:TCP,    'nwdiy/packet/ip/tcp')
      autoload(:UDP,    'nwdiy/packet/ip/udp')
      autoload(:ICMP4,  'nwdiy/packet/ip/icmp4')
      autoload(:OSPFv2, 'nwdiy/packet/ip/ospf')
    end

    class IPv4
      include NwDiy::Linux

      ################################################################
      # プロトコル番号とプロトコルクラスの対応表
      # (遅延初期化することで、使わないクラス配下のデータクラスまで
      #  無駄に読み込んでしまうことを防ぐ)
      @@kt = KlassType.new({ IP::ICMP4 => 1 })

      ################################################################
      # パケット生成
      ################################################################
      def self.cast(pkt = nil)
        pkt.kind_of?(self) and
          return pkt
        self.new(pkt.respond_to?(:to_pkt) ? pkt.to_pkt : pkt)
      end

      # 受信データからパケットを作る
      def initialize(pkt = nil)
        case pkt
        when String
          pkt.bytesize >= 20 or
            raise TooShort.new(pkt)
          @vhl = pkt[0].btoh
          @tos = pkt[1].btoh
          @length = pkt[2..3].btoh
          @id = pkt[4..5].btoh
          @off = pkt[6..7].btoh
          @ttl = pkt[8].btoh
          self.proto = pkt[9].btoh
          @cksum = pkt[10..11].btoh
          @src = IPAddr.new_ntoh(pkt[12..15])
          @dst = IPAddr.new_ntoh(pkt[16..19])
          @option = pkt[20..(self.hlen-1)]
          self.data = pkt[self.hlen..@length]
          pkt[0..@length] = ''
          @trailer = pkt
        when nil
          @vhl = 0x45
          @tos = @id = @off = @ttl = @proto = @cksum = 0
          @length = 20
          @src = @dst = IPAddr.new('0.0.0.0')
          @option = @data = ''
        else
          raise InvalidData.new(pkt)
        end
      end

      ################################################################
      # 各フィールドの値
      ################################################################

      attr_accessor :tos, :id, :ttl, :cksum, :option
      attr_reader :length, :proto, :cksum, :src, :dst, :data

      def version
        @vhl >> 4
      end
      def hlen
        (@vhl & 0xf) << 2
      end

      def df
        !!(@off & 0x4000)
      end
      def df=(val)
        if val
          @off |=  0x4000
        else
          @off &=~ 0x4000
        end
      end
      def more
        !!(@off & 0x2000)
      end
      def more=(val)
        if val
          @off |=  0x2000
        else
          @off &=~ 0x2000
        end
      end
      def offset
        @off & 0x1fff
      end
      def offset=(val)
        @off = (@off & 0x6000) | (val & 0x1fff)
      end

      def proto=(val)
        # 代入されたら @data の型も変わる
        @proto = val
        @data and
          self.data = @data
      end

      def src=(val)
        @src = IPAddr.new(val, Socket::AF_INET)
      end
      def dst=(val)
        @dst = IPAddr.new(val, Socket::AF_INET)
      end

      def data=(val)
        # 代入されたら @length, @proto の値も変わる
        # 逆に val の型が不明なら、@proto に沿って @data の型が変わる
        dtype = @@kt.type(val)
        dtype and
          @proto = dtype
        @data = @@kt.klass(@proto).cast(val)
        @length = self.hlen + @data.bytesize
      end

      ################################################################
      # その他の諸々
      def to_pkt
        @vhl.htob8 + @tos.htob8 + @length.htob16 +
          @id.htob16 + @off.htob16 +
          @ttl.htob8 + @proto.htob8 + @cksum.htob16 +
          @src.hton + @dst.hton + @option +
          @data.to_pkt
      end

      def bytesize
        @length
      end

      def to_s
        name = resolv('/etc/protocols', @proto)
        name.kind_of?(Array) and
          name = name[0]
        "[IPv4 #@src > #@dst #{name} #@data]"
      end
    end

    class ARP
    end
  end
end
