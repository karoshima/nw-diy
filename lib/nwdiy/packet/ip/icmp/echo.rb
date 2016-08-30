#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require 'nwdiy/packet/ip/icmp'

class NwDiy::Packet::IP::ICMP
  class EchoRequest
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
        pkt.bytesize >= 8 or
          raise TooShort.new(pkt)
        @id = pkt[0..1].btoh
        @seq = pkt[2..3].btoh
        pkt[0..3] = ''
        @data = pkt
      when nil
        @id = rand(0x10000)
        @seq = rand(0x10000)
        @data = 'NW-DIY ICMP'
      else
        raise InvalidData.new(pkt)
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
