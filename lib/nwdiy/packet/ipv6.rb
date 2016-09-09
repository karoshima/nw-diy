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

    class IPv6
      include IP
      include NwDiy::Linux

      ################################################################
      # プロトコル番号とプロトコルクラスの対応表
      # (遅延初期化することで、使わないクラス配下のデータクラスまで
      #  無駄に読み込んでしまうことを防ぐ)
      @@kt = KlassType.new({ IP::ICMP6 => 58 })

      ################################################################
      # 受信データからパケットを作る
      def initialize(pkt = nil)
        super()
        case pkt
        when String
          pkt.bytesize >= 40 or
            raise TooShort.new(pkt)
          @vtf = pkt[0..3].btoh
          @length = pkt[4..5].btoh
          @next = pkt[6].btoh
          @hlim = pkt[7].btoh
          @src = IPAddr.new_ntoh(pkt[8..23])
          @dst = IPAddr.new_ntoh(pkt[24..39])
          self.data = pkt[40..@length]
          pkt[0..@length-1] = ''
          @trailer = pkt
        when nil
          @vtf = 0x60000000
          @length = 40
          @next = 0
          @hlim = 0
          @src = @dst = IPAddr.new('::')
          @trailer = ''
        else
          raise InvalidData.new(pkt)
        end
      end

      ################################################################
      # 各フィールドの値
      ################################################################

      def version
        (@vtf & 0xf0000000) >> 28
      end
      def tc=(val)
        @vtf = (@vtf & 0xf00fffff) | ((val << 20) & 0x0ff00000)
      end
      def tc
        (@vtf & 0x0ff00000) >> 20
      end
      def flow=(val)
        @vtf = (@vtf & 0xfff00000) | (val & 0x000fffff)
      end
      def flow
        @vtf & 0x000fffff
      end

      attr_writer :length
      def length
        @auto_compile ? (40 + @data.bytesize) : @length
      end

      attr_writer :next
      def next
        @auto_compile ? @@kt.type(@data, @next) : @next
      end

      attr_accessor :hlim

      def src=(val)
        @src = IPAddr.new(val, Socket::AF_INET6)
      end
      attr_reader :src

      def dst=(val)
        @dst = IPAddr.new(val, Socket::AF_INET6)
      end
      attr_reader :dst

      def data=(val)
        @data = val.kind_of?(Packet) ? val : Binary.new(val)
      end
      def data
        (@auto_compile && @data.kind_of?(Binary) && @@kt.klass(@next) != Binary) and
          @data = @@kt.klass(@next).new(@data)
        @data
      end

      ################################################################
      # その他の諸々
      def to_pkt
        @vtf.htob32 + self.length.htob16 + self.next.htob8 + @hlim.htob8 +
          @src.hton + @dst.hton + @data.to_pkt + @trailer
      end

      # L4 ヘッダのチェックサム計算のための仮ヘッダ
      def pseudo_header(proto, len)
        @src.hton + @dst.hton + 0.htob8 + l4len.htob32 + proto.htob32
      end

      def bytesize
        self.length
      end

      def to_s
        name = resolv('/etc/protocols', @next)
        name.kind_of?(Array) and
          name = name[0]
        "[IPv6 #@src > #@dst #{name} #@data]"
      end
    end
  end
end
