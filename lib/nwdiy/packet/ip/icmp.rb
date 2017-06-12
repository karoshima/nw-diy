#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
#
# ICMP パケットの処理
#
# icmp = NwDiy::Packet::IP::ICMP.new
#    初期化された ICMP フレームを作成します。
#
# icmp = NwDiy::Packet::IP::ICMP.new(バイナリデータ)
#    バイナリデータをパケットデータとして読み込み、
#    ICMP パケットを作成します。
#
# icmp.type, icmp.code
#    ICMP パケットの各フィールドを読み書きします。
#
# icmp.data
#    ICMP パケットのデータ部 (type 毎に異なる部分) を読み書きします。
#
# icmp.bytesize
#    ICMP パケットのバイト長を返します
# 
# icmp.to_pkt
#    ICMP パケットのバイナリデータ化します
#
# icmp.to_s
#    ICMP パケットをを可読化します
#
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
          return pkt if pkt.kind_of?(self)
          self.new(pkt.respond_to?(:to_pkt) ? pkt.to_pkt : pkt)
        end

        # 受信データからパケットを作る
        def initialize(pkt = nil)
          super()
          case pkt
          when String
            unless pkt.bytesize >= 4
              raise TooShort.new("ICMP", 4, pkt)
            end
            @type = pkt[0].btoh
            @code = pkt[1].btoh
            @cksum = pkt[2..3].btoh
            pkt[0..3] = ''
            self.data = pkt
          when nil
            @type = @code = @cksum = 0
            @data = Binary.new('')
          else
            raise InvalidData.new "What is '#{pkt}'?"
          end
        end

        ################################################################
        # 各フィールドの値
        ################################################################

        attr_reader :type
        def type=(val)
          oldtype = @type
          @type = val
          if @data
            begin
              self.data = @data.to_pkt
            rescue => e
              @type = oldtype
              raise e
            end
          end
        end

        attr_accessor :code

        def cksum
          @auto_compile ? calc_cksum(self.pkt_with_cksum(0)) : @cksum
        end
        attr_writer :cksum
        def cksum_ok?
          return @auto_compile if @auto_compile
          calc_cksum(self.pkt_with_cksum(0)) == @cksum
        end

        attr_reader :data
        def data=(kt, val)
          # 代入されたら @proto の値も変わる
          # 逆に val の型が不明なら、@proto に沿って @data の型が変わる
          newtype = kt.type(val)
          if newtype == 0
            @data = kt.klass(@type).new(val)
          else
            @type = newtype
            @data = val
          end
        end

        ################################################################
        # @auto_compile 設定
        def auto_compile=(bool)

          # 解除するまえに、これまでの正常値を設定しておく
          unless bool
            @cksum = self.cksum
          end

          # 値を反映して、データ部にも伝える
          @auto_compile = bool
          @data.auto_compile = bool if @data.respond_to?(:auto_compile=)
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
