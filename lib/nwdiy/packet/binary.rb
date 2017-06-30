#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
#
# よく分からないパケットの定義
#
# pkt = NwDiy::Packet::Binary.new(バイナリデータ)
#    バイナリデータをパケットデータとして読み込み、バイナリデータの
#    フレームを作成します。
#
# pkt.bytesize
#    バイナリパケットのバイト長を返します
#
# pkt.to_pkt
#    バイナリパケットをバイナリデータ化します
#
# pkt.to_s
#    バイナリパケットを可読化します
#
################################################################

require_relative '../../nwdiy'

require 'nwdiy/util'

module NwDiy
  module Packet

    # 型がよく分からない
    # なにかのバイナリデータ
    class Binary

      def initialize(pkt)
        super()
        pkt = pkt.to_pkt if pkt.respond_to?(:to_pkt)
        unless pkt.instance_of?(String)
          raise InvalidData.new "What is '#{pkt}'?"
        end
        @bin = pkt  # データそのもの
        @txt = nil  # self.to_s 表示用キャッシュ
      end

      def to_pkt
        @bin
      end
      def bytesize
        @bin.bytesize
      end

      def to_s
        unless @txt
          @txt = ''
          @bin[0..15].unpack('N*a*').each do |val|
            if val.kind_of?(Integer)
              @txt += '%08x ' % val
            else
              val.each_byte {|c| @txt += sprintf('%02x', c) }
            end
          end
        end
        "[Binary #{@txt}]"
      end

    end
  end
end
