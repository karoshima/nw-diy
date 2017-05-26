#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require_relative '../../nwdiy'

require 'nwdiy/packet/macaddr'
require 'ipaddr'

module NwDiy
  module Packet

    class ARP
      include Packet

      ################################################################
      # 受信データからパケットを作る
      def initialize(pkt = nil)
        case pkt
        when String
          raise TooShort.new("ARP", 28, pkt) unless pkt.bytesize >= 28
          @hard = pkt[0..1].btoh
          @prot = pkt[2..3].btoh
          @hlen = pkt[4].btoh
          @plen = pkt[5].btoh
          @oper = pkt[6..7].btoh
          @sndmac = MacAddr.new(pkt[8..13])
          @sndip4 = IPAddr.new_ntoh(pkt[14..17])
          @tgtmac = MacAddr.new(pkt[18..23])
          @tgtip4 = IPAddr.new_ntoh(pkt[24..27])
          pkt[0..27] = ''
          @trailer = pkt
        when nil
          @hard = 1
          @prot = 0x0800
          @hlen = 6
          @plen = 4
          @oper = nil
          @sndmac = MacAddr.new("\0\0\0\0\0\0")
          @sndip4 = IPAddr.new('0.0.0.0')
          @tgtmac = MacAddr.new("\0\0\0\0\0\0")
          @tgtip4 = IPAddr.new('0.0.0.0')
          @trailer = ''
        else
          raise InvalidData.new "What is '#{pkt}'?"
        end
      end

      ################################################################
      # 各フィールドの値
      ################################################################
      attr_accessor :hard, :prot, :hlen, :plen

      attr_reader :oper
      def oper=(op)
        case op
        when :request
          @oper = 1
        when :response, :reply
          @oper = 2
        when Integer
          @oper = op
        else
          raise InvalidData.new(op)
        end
      end
      def request?
        @oper == 1
      end
      def response?
        @oper == 2
      end
      def reply?
        @oper == 2
      end

      attr_accessor :sndmac, :sndip4, :tgtmac, :tgtip4

      ################################################################
      # その他の諸々
      def to_pkt
        @hard.htob16 + @prot.htob16 +
          @hlen.htob8 + @plen.htob8 + @oper.htob16 +
          @sndmac.hton + @sndip4.hton +
          @tgtmac.hton + @tgtip4.hton + @trailer
      end

      def bytesize
        28
      end

      def to_s
        name = case @oper
               when 1 then 'Request'
               when 2 then 'Reply'
               else        "Unknown(#{@oper})"
               end
        "[ARP #{name} #{@sndmac}/#{@sndip4} => #{@tgtmac}/#{@tgtip4}]"
      end

    end
  end
end
