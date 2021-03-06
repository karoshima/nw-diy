#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
#
# ICMP echo パケットの定義
#
# echo = NwDiy::Packet::IP::ICMP::EchoRequest.new
#    初期化された ICMP EchoRequest フレームを作成します。
#
# echo = NwDiy::Packet::IP::ICMP::EchoReply.new
#    初期化された ICMP EchoReply フレームを作成します。
#
# echo = NwDiy::Packet::IP::ICMP::EchoRequest.new(バイナリデータ)
#    バイナリデータをパケットデータとして読み込み、
#    ICMP EchoRequest パケットを作成します。
#
# echo = NwDiy::Packet::IP::ICMP::EchoReply.new(バイナリデータ)
#    バイナリデータをパケットデータとして読み込み、
#    ICMP EchoReply パケットを作成します。
#
# echo.id, echo.seq
#    ICMP Echo パケットの各フィールドを読み書きします。
#
# echo.data
#    ICMP Echo パケットのデータ部を読み書きします。
#
# echo.bytesize
#    ICMP Echoバイト長を返します
# 
# echo.to_pkt
#    ICMP Echo パケットをバイナリデータ化します
#
# echo.to_s
#    ICMP Echo パケットを可読化します
#
################################################################

require 'nwdiy/packet/ip/icmp'

class NwDiy::Packet::IP::ICMP
  class EchoRequest
    ################################################################
    # パケット生成
    ################################################################
    def self.cast(pkt = nil)
      return pkt if pkt.kind_of?(self)
      self.new(pkt.respond_to?(:to_pkt) ? pkt.to_pkt : pkt)
    end

    # 受信データからパケットを作る
    def initialize(pkt = nil)
      case pkt
      when String
        unless pkt.bytesize >= 8
          raise TooShort.new("Echo", 8, pkt)
        end
        @id = pkt[0..1].btoh
        @seq = pkt[2..3].btoh
        pkt[0..3] = ''
        @data = pkt
      when nil
        @id = rand(0x10000)
        @seq = rand(0x10000)
        @data = 'NW-DIY ICMP Echo'
      else
        raise InvalidData.new "What is '#{pkt}'?"
      end
    end

    ################################################################
    # 各フィールドの値
    ################################################################

    attr_accessor :id, :seq, :data

    ################################################################
    # その他

    def to_pkt
      @id.htob16 + @seq.htob16 + @data
    end

    def bytesize
      4 + @data.bytesize
    end

    def to_s
      "[EchoRequest seq=#@seq]"
    end
  end

  class EchoReply < EchoRequest
    def to_s
      "[EchoReply   seq=#@seq]"
    end
  end
end
