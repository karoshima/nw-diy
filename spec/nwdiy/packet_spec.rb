#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require "spec_helper"

################################################################
# パケットの概要
################
# 各種パケットは Nwdiy::Packet のサブクラスのインスタンスになります。
# イーサネットフレームもその中の IPv4 パケットもその中の UDP も
# いずれも Nwdiy::Packet のサブクラスに属します。
#
################
# パイプとの関係
#
# NW-DIY には機能インスタンスをパイプで繋ぐ仕組みがあります。
# 機能によっては、パケットの向きを意識する必要があります。
# そのため Nwdiy::Packet のサブクラスである各パケットは、
# パケットの向きという属性を持っています。
################################################################

RSpec.describe Nwdiy::Packet do
  it "calculate checksum" do
    data = ["\0\0\0\0\0\0\0\0", "\0\0\0\0\0\0\0\0"]
    expect(Nwdiy::Packet.calc_cksum(*data)).to be(0xffff)
  end

  it 'has a direction' do
    data =
      "\x00\x00\x0e\x00\x00\x01" + # eth dst
      "\x00\x00\x0e\x00\x00\x02" + # eth src
      "\x08\x00" +                 # eth type
      "\x45\x00\x00\x54\xf1\x18" + # IPv4 vhl, tos, len, id
      "\x40\x00\x40\x01\x31\x80" + # IPv4 frag, ttl, proto, cksum
      "\x0a\x00\x02\x0f" +         # IPv4 src
      "\x0a\x00\x02\x02" +         # IPv4 dst
      "\x08\x00\xc3\x7c" +         # ICMP type, code, cksum
      "\x24\x5b\x00\x01" +         # ICMP id, seq
      "\x9e\x3e\x9d\x59\0\0\0\0" + # ICMP timestamp
      "\x10\xbc\x05\x00\0\0\0\0" +         # ICMP data
      "\x10\x11\x12\x13\x14\x15\x16\x17" + # ICMP data
      "\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f" + # ICMP data
      "\x20\x21\x22\x23\x24\x25\x26\x27" + # ICMP data
      "\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f" + # ICMP data
      "\x20\x31\x32\x33\x34\x35\x36\x37" + # ICMP data
      ""
    pkt = Nwdiy::Packet::Ethernet.new(data)
    expect(pkt.class).to be Nwdiy::Packet::Ethernet
    expect(pkt.auto_compile).to be true
    expect(pkt.data.auto_compile).to be true
    expect(pkt.direction).to be :UNKNOWN
    expect(pkt.data.direction).to be :UNKNOWN

    pkt.auto_compile = false
    expect(pkt.auto_compile).to be false
    expect(pkt.data.auto_compile).to be false

    pkt.dir_to_right
    expect(pkt.direction).to be :LEFT_TO_RIGHT
    expect(pkt.data.direction).to be :LEFT_TO_RIGHT
  end
end
