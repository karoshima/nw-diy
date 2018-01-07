#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# Nwdiy::Packet::IPv4 は IPv4 アドレスです。
# 仕様については spec/nwdiy/packet/ipv4_spec.rb を参照してください
################################################################

require "ipaddr"

class Nwdiy::Packet::IPv6Addr < Nwdiy::Packet
  def_head :uint16, :a0, :a1, :a2, :a3, :a4, :a5, :a6, :a7

  def self.bytesize
    16
  end
  def bytesize
    16
  end

  def initialize(data = nil)
    case data
    when Nwdiy::Packet::IPv6Addr
      super(data.to_pkt)
    when Nwdiy::Packet::IPv4Addr
      super([0, 0, 0xffff].pack("N3") + data.to_pkt) # v4mapped
    when Integer
      list = [(data >> 96) & 0xffffffff, (data >> 64) & 0xffffffff, (data >> 32) & 0xffffffff, (data >>  0) & 0xffffffff]
      super(list.pack("N4"))
    when String
      begin
        data.gsub!(/\b(\d+\.\d+)\.(\d+\.\d+)\z/, '\1:\2')
        leftright = data.split(/::/)
        left = leftright[0].split(/:/)
        if 8 < left.length
          raise InvalidAddressError.new "#{data} is not IPv6 address format"
        end
        if leftright[1]
          right = leftright[1].split(/:/)
          if 8 < left.length + right.length
            raise InvalidAddressError.new "#{data} is not IPv6 address format"
          end
          left[ 8 - right.length, right.length] = right
        end
        left.map! do |u16|
          case u16
          when nil
            0
          when /\A\h{1,4}\z/
            u16.to_i(16)
          when /\A(\d+)\.(\d+)\z/
            u16 = [$1,$2].map{|u8|u8.to_i}
            u16[0] * 256 + u16[1]
          else
            raise InvalidAddressError.new "#{data} is not IPv6 address format"
          end
        end
        super(left.pack("n8"))
      rescue InvalidAddressError => e
        if data.bytesize == 16
          super(data)
        else
          raise e
        end
      end
    when nil
      super(nil)
    else
      raise InvalidAddressError.new "#{data} is not IPv6 address format"
    end
  end
  class InvalidAddressError < Exception; end

  def inspect
    if self.a0 == 0 && self.a1 == 0 && self.a2 == 00 && self.a3 == 0 && self.a4 == 0 && self.a5 == 0xffff
      sprintf("::ffff:%u.%u.%u.%u", self.a6 / 256, self.a6 % 256, self.a7 / 256, self.a7 % 256)
    else
      a = [self.a0, self.a1, self.a2, self.a3, self.a4, self.a5, self.a6, self.a7]
      str = a.map!{|b|b.to_s(16)}.join(":")
      loop do
        break if str.sub!(/\A0:0:0:0:0:0:0:0\z/, '::')
        break if str.sub!(/\b0:0:0:0:0:0:0\b/, ':')
        break if str.sub!(/\b0:0:0:0:0:0\b/, ':')
        break if str.sub!(/\b0:0:0:0:0\b/, ':')
        break if str.sub!(/\b0:0:0:0\b/, ':')
        break if str.sub!(/\b0:0:0\b/, ':')
        break if str.sub!(/\b0:0\b/, ':')
        break
      end
      str.sub(/:{3,}/, '::')
    end
  end

  def unicast?
    !self.multicast?
  end
  def multicast?
    (self.a0 & 0xff00) == 0xff00
  end
  def loopback?
    self.a0 == 0 &&
      self.a1 == 0 &&
      self.a2 == 0 &&
      self.a3 == 0 &&
      self.a4 == 0 &&
      self.a5 == 0 &&
      self.a6 == 0 &&
      self.a7 == 1
  end
  def nodelocal?
    self.a0 == 0xff01
  end
  def linklocal?
    (0xfe80 <= self.a0 && self.a0 < 0xfec0) || self.a0 == 0xff02
  end
  def global?
    !self.loopback? && !self.nodelocal? && !self.linklocal?
  end
end
