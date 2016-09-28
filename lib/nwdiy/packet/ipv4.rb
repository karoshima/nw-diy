#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require 'ipaddr'

require_relative '../../nwdiy'

require 'nwdiy/util'
require 'nwdiy/packet/ip'

module NwDiy
  module Packet

    class IPv4

      include IP
      # @auto_compile というフラグで、自動計算するかしないか設定します

      include NwDiy::Linux

      ################################################################
      # プロトコル番号とプロトコルクラスの対応表
      # (遅延初期化することで、使わないクラス配下のデータクラスまで
      #  無駄に読み込んでしまうことを防ぐ)
      @@kt = KlassType.new({ IP::ICMP4 => 1 })

      ################################################################
      # 受信データからパケットを作る
      def initialize(pkt = nil)
        super()
        case pkt
        when String
          pkt.bytesize >= 20 or
            raise TooShort.new(pkt)
          @vhl = pkt[0].btoh
          self.version == 4 or
            raise InvalidData, pkt
          self.hlen >= 5 or
            raise InvalidData, pkt
          @tos = pkt[1].btoh
          @length = pkt[2..3].btoh
          @id = pkt[4..5].btoh
          @off = pkt[6..7].btoh
          @ttl = pkt[8].btoh
          @proto = pkt[9].btoh
          @cksum = pkt[10..11].btoh
          @src = IPAddr.new_ntoh(pkt[12..15])
          @dst = IPAddr.new_ntoh(pkt[16..19])
          @option = pkt[20..(self.hlen-1)]
          self.data = pkt[self.hlen..@length-1]
          pkt[0..@length-1] = ''
          @trailer = pkt
        when nil
          @vhl = 0x45
          @tos = 0
          @length = 20
          @id = rand(0x10000)
          @off = 0
          @ttl = 64
          @proto = 0
          @cksum = 0
          @src = @dst = IPAddr.new('0.0.0.0')
          @option = ''
          @data = Binary.new('')
          @trailer = ''
        else
          raise InvalidData.new(pkt)
        end
      end

      ################################################################
      # 各フィールドの値
      ################################################################

      def version
        @vhl >> 4
      end
      def hlen
        (@vhl & 0xf) << 2
      end

      attr_accessor :tos

      attr_writer :length
      def length
        @auto_compile ? (self.hlen + @data.bytesize) : @length
      end

      attr_accessor :id

      def df=(val)
        if val
          @off |=  0x4000
        else
          @off &=~ 0x4000
        end
      end
      def df
        (@off & 0x4000) != 0
      end
      def more=(val)
        if val
          @off |=  0x2000
        else
          @off &=~ 0x2000
        end
      end
      def more
        (@off & 0x2000) != 0
      end
      def offset=(val)
        @off = (@off & 0x6000) | (val & 0x1fff)
      end
      def offset
        @off & 0x1fff
      end

      attr_accessor :ttl

      def proto=(val)
        @proto = val
        @data and
          self.data = @data.to_pkt
      end
      def proto
        @auto_compile ? @@kt.type(@data, @proto) : @proto
      end

      attr_writer :cksum
      def cksum
        @auto_compile ? calc_cksum(self.pkt_with_cksum(0)) : @cksum
      end
      def cksum_ok?
        @auto_compile or
          calc_cksum(self.pkt_with_cksum(0)) == @cksum
      end

      def src=(val)
        @src = IPAddr.new(val, Socket::AF_INET)
      end
      attr_reader :src

      def dst=(val)
        @dst = IPAddr.new(val, Socket::AF_INET)
      end
      attr_reader :dst

      attr_accessor :option

      def data=(val)
        @data = val.kind_of?(Packet) ? val : Binary.new(val)
      end
      def data
        (@auto_compile && @data.kind_of?(Binary) && @@kt.klass(@proto) != Binary) and
          @data = @@kt.klass(@type).new(@data)
        @data
      end

      attr_accessor :trailer # IP パケットの末尾以降の余計なデータ

      ################################################################
      # その他の諸々
      def to_pkt
        self.pkt_with_cksum(self.cksum)
      end
      def pkt_with_cksum(sum)
        @vhl.htob8 + @tos.htob8 + self.length.htob16 +
          @id.htob16 + @off.htob16 +
          @ttl.htob8 + self.proto.htob8 + sum.htob16 +
          @src.hton + @dst.hton + @option +
          @data.to_pkt + @trailer
      end

      # L4 ヘッダのチェックサム計算のための仮ヘッダ
      def pseudo_header(proto, len)
        @src.hton + @dst.hton + proto.htob16 + len.htob16
      end

      def bytesize
        self.length
      end

      def to_s
        name = resolv('/etc/protocols', @proto)
        name.kind_of?(Array) and
          name = name[0]
        "[IPv4 #@src > #@dst #{name} #@data]"
      end
    end

  end
end
