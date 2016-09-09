#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

module NwDiy
  module Packet
    module IP
      class ICMP

        include Packet
        # @auto_compile というフラグで、自動計算するかしないか設定します

        autoload(:EchoRequest, 'nwdiy/packet/ip/icmp/echo')
        autoload(:EchoReply, 'nwdiy/packet/ip/icmp/echo')

        ################################################################
        # プロトコル番号とプロトコルクラスの対応表

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
          super()
          case pkt
          when String
            pkt.bytesize >= 4 or
              raise TooShort.new(pkt)
            @type = pkt[0].btoh
            @code = pkt[1].btoh
            @cksum = pkt[2..3].btoh
            pkt[0..3] = ''
            self.data = pkt
          when nil
            @type = @code = @cksum = 0
            @data = Binary.new('')
          else
            raise InvalidData.new(pkt)
          end
        end

        ################################################################
        # 各フィールドの値
        ################################################################

        attr_reader :type
        def type=(val)
          @type = val
          self.data = @data
        end

        attr_accessor :code

        def cksum
          @auto_compile ? calc_cksum(self.pkt_with_cksum(0)) : @cksum
        end
        attr_writer :cksum
        def cksum_ok?
          @auto_compile or
            calc_cksum(self.pkt_with_cksum(0)) == @cksum
        end

        attr_reader :data
        def data=(kt, val)
          # 代入されたら @proto の値も変わる
          # 逆に val の型が不明なら、@proto に沿って @data の型が変わる
          dtype = kt.type(val)
          dtype and
            @type = dtype
          @data = kt.klass(@type).cast(val)
        end

        ################################################################
        # その他の諸々
        def to_pkt
          pkt_with_cksum(self.cksum)
        end
        def pkt_with_cksum(sum)
          @type.htob8 + @code.htob8 + sum.htob16 + @data.to_pkt
        end

        def bytesize
          4 + @data.bytesize
        end

        def to_s
          "type=#@type code=#@code #@data"
        end
      end
    end
  end
end
