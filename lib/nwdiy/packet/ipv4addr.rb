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

class Nwdiy::Packet::IPv4Addr < Nwdiy::Packet
  def_head :uint32, :addr

  def self.bytesize
    4
  end
  def bytesize
    4
  end

  def initialize(data)
    super(addr: self.class.addr2uint32(data))
  end

  def to_s
    [self.addr].pack("N")
  end
  def inspect
    sprintf("%u.%u.%u.%u",
            (self.addr & 0xff000000) >> 24,
            (self.addr & 0x00ff0000) >> 16,
            (self.addr & 0x0000ff00) >>  8,
            (self.addr & 0x000000ff))
  end

  def unicast?
    !self.multicast?
  end
  def loopback?
    (self.addr & 0xff000000) == 0x7f000000
  end
  def multicast?
    (self.addr & 0xf0000000) == 0xe0000000
  end

  def broadcast?(mask)
    (self.addr | self.addr2uint32(mask)) == 0xffffffff
  end

  def included?(address, mask)
    ((self.addr ^ address) & self.addr2uint32(mask)) == 0
  end

  private

  MLEN2MASK = [ 0x00000000, 
                0x80000000, 0xc0000000, 0xe0000000, 0xf0000000,
                0xf8000000, 0xfc000000, 0xfe000000, 0xff000000,
                0xff800000, 0xffc00000, 0xffe00000, 0xfff00000,
                0xfff80000, 0xfffc0000, 0xfffe0000, 0xffff0000,
                0xffff8000, 0xffffc000, 0xffffe000, 0xfffff000,
                0xfffff800, 0xfffffc00, 0xfffffe00, 0xffffff00,
                0xffffff80, 0xffffffc0, 0xffffffe0, 0xfffffff0,
                0xfffffff8, 0xfffffffc, 0xfffffffe, 0xffffffff ]

  def self.addr2uint32(addr)
    if addr.bytesize == 4
      return addr.unpack("N")[0]
    elsif addr =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/
      a = [$1,$2,$3,$4].map{|c|c.to_i}
      if a[0] > 255 || a[1] > 255 || a[2] > 255 || a[3] > 255
        raise TypeError.new("Invalid IPv4 addr '#{addr}'")
      end
      return a[0] << 24 | a[1] << 16 | a[2] << 8 | a[3]
    elsif 0 <= addr && addr <= 32
      return MLEN2MASK[addr]
    else
      return addr
    end
  end
end
