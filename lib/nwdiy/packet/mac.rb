#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require "nwdiy/packet"

class Nwdiy::Packet::Mac < Nwdiy::Packet

  ################
  # Nwdiy::Packet に沿ったメソッド

  def_field :byte6, :addr

  def initialize(data)
    case data
    when /^......$/
      super(data)
    when /^(\h\h?)[:\.-](\h\h?)[:\.-](\h\h?)[:\.-](\h\h?)[:\.-](\h\h?)[:\.-](\h\h?)$/
      super([$1,$2,$3,$4,$5,$6].map{|c|c.hex}.pack("C6"))
    else
      raise TypeError.new("Invalid Mac address '#{data.dump}'")
    end
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
      othermac = Nwdiy::Packet::Mac.new(other)
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
