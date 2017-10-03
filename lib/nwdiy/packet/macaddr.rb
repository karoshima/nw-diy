#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# Nwdiy::Packet::Mac は MAC アドレスです。
# 仕様については spec/nwdiy/packet/mac_spec.rb を参照してください
################################################################

require "nwdiy/packet"

class Nwdiy::Packet::MacAddr < Nwdiy::Packet

  def_field :byte6, :addr

  def initialize(data)
    case data
    when Hash
      if data[:broadcast]
        if data[:unicast]
          raise TypeError.new("Broadcast MAC cannot be unicast")
        end
        if data[:local]
          raise TypeError.new("Broadcast MAC cannot be local")
        end
        return super("\xff\xff\xff\xff\xff\xff")
      end
      if data[:multicast]
        if data[:unicast]
          raise TypeError.new("Multicast MAC cannot be unicast")
        end
        um = 1
      else
        um = 0
      end
      if data[:global] && data[:local]
        raise TypeError.new("MAC cannot be global & local")
      end
      gl = data[:local] ? 2 : 0
      return super(([um+gl] + (1..5).map { rand(256) }).pack("C6"))
    when /^......$/
      return super(data)
    when /^(\h\h?)[:\.-](\h\h?)[:\.-](\h\h?)[:\.-](\h\h?)[:\.-](\h\h?)[:\.-](\h\h?)$/
      return super([$1,$2,$3,$4,$5,$6].map{|c|c.hex}.pack("C6"))
    end
    raise TypeError.new("Invalid Mac address '#{data.dump}'")
  end

  def to_s
    self.addr
  end
  def bytesize
    6
  end
  def self.bytesize
    6
  end
  def inspect
    self.addr.unpack("C6").map{|c| "%02x"%c }.join(":")
  end

  ################
  # Mac 独自メソッド
  def ==(other)
    case other
    when /^......$/
      return @addr == other
    when /^(\h\h?)[:\.-](\h\h?)[:\.-](\h\h?)[:\.-](\h\h?)[:\.-](\h\h?)[:\.-](\h\h?)$/
      othermac = Nwdiy::Packet::MacAddr.new(other)
      return @addr == othermac.addr
    else
      raise TypeError.new("Invalid Mac address '#{data.dump}'")
    end
  end

  def unicast?
    (@addr.unpack("C")[0] & 0x01) == 0
  end
  def multicast?
    !self.unicast?
  end
  def broadcast?
    @addr == "\xFF\xFF\xFF\xFF\xFF\xFF".force_encoding("ASCII-8BIT")
  end
  def global?
    self.broadcast? || (@addr.unpack("C")[0] & 0x02) == 0
  end
  def local?
    !self.broadcast? && !self.global?
  end
end
