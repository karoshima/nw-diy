#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# IPAddr クラスそっくりな MacAddr クラス

module NwDiy
  module Packet
    class MacAddr

      # バイナリデータから MAC データを作って返す
      def self::new_ntoh(addr)
        self.new(addr)
      end

      def self::ntop(addr)
        self.new(addr).to_s
      end

      def initialize(addr)
        if addr.is_a?(NwDiy::Packet::MacAddr)
          @addr = addr.hton
          return
        end
        if addr == :local
          @addr = ([2] + (1..5).map{rand(256)}).pack('C6')
          return
        end
        if addr.bytesize == 6
          @addr = addr
          return
        end
        match = /^(\h\h?):(\h\h?):(\h\h?):(\h\h?):(\h\h?):(\h\h?)$/.match(addr)
        match or
          match = /^(\h\h?)-(\h\h?)-(\h\h?)-(\h\h?)-(\h\h?)-(\h\h?)$/.match(addr)
        match or
          match = /^(\h\h?)\.(\h\h?)\.(\h\h?)\.(\h\h?)\.(\h\h?)\.(\h\h?)$/.match(addr)
        match or
          raise ArgumentError.new("invalid MAC addr: #{addr}")
        @addr = match[1..6].map{|h|h.hex}.pack('C6')
      end

      def hton
        @addr
      end

      def to_s
        @addr.unpack('C6').map{|h|sprintf('%02x',h)}.join(':')
      end
      alias inspect to_s
      alias to_string to_s

      def unicast?
        (@addr.unpack('C')[0] & 0x01) == 0
      end
      def multicast?
        !self.unicast?
      end
      def global?
        (@addr.unpack('C')[0] & 0x01) == 0
      end
      def local?
        !self.global?
      end

      # hash のキーにするために
      def hash
        @addr.unpack('C6').inject {|a,b| a*256+b}
      end
      def eql?(other)
        other.kind_of?(NwDiy::Packet::MacAddr) && self.hash == other.hash
      end
      alias == eql?
    end
  end
end
