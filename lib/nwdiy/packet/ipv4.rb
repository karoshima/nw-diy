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
          unless pkt.bytesize >= 20
            raise TooShort.new("IPv4", 20, pkt)
          end
          @vhl = pkt[0].btoh
          unless self.version == 4
            raise InvalidData.new "IPv4 version must be 4, but it comes #{self.version}."
          end
          unless self.hlen >= 5
            raise InvalidData.new "IPv4 header length must be 5(20byte), but it comes #{self.hlen}."
          end
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
          raise InvalidData.new "What is '#{pkt}'?"
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
        oldproto = @proto
        @proto = val
        @data and
          begin
            self.data = @data.to_pkt
          rescue => e
            @proto = oldproto
            raise e
          end
      end
      attr_reader :proto

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
        ktype = @@kt.type(val)
        if ktype == 0
          @data = @@kt.klass(@proto).new(val)
        else
          @proto = ktype
          @data = val
        end
        @data
      end
      attr_reader :data

      attr_accessor :trailer # IP パケットの末尾以降の余計なデータ

      ################################################################
      # @auto_compile 設定
      def auto_compile=(bool)

        # 解除するまえに、これまでの正常値を設定しておく
        unless bool
          @length = self.length
          @cksum = self.cksum
        end

        # 値を反映して、データ部にも伝える
        @auto_compile = bool
        if @data.respond_to?(:auto_compile=)
          @data.auto_compile = bool
        end
      end

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
        if name.kind_of?(Array)
          name = name[0]
        end
        "[IPv4 #@src > #@dst #{name} #@data]"
      end
    end

  end
end
