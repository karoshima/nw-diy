#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require 'nwdiy/packet/ip/icmp'

class NwDiy::Packet::ICMP
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
        # no default value
      else
        raise InvalidData.new(pkt)
      end
    end

    ################################################################
    # 各フィールドの値
    ################################################################

    attr_accessor :id, :seq, :data
    def compile(overwrite = false)
    end

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
