#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# EtherIP frame class
#
# [class method]
#
# new -> Nwdiy::Packet::EtherIP
#    (implemented on Nwdiy::Packet)
#    create EtherIP header instance
#
# new(bytes) -> Nwdiy::Packet::EtherIP
#    (implemented on Nwdiy::Packet)
#    create EtherIP header instance with the bytes
#
# new(Hash) -> Nwdiy::Packet::EtherIP
#    (implemented on Nwdiy::Packet)
#    create EtherIP header instance with the fields.
#    you can specify below.
#
#    :data    data (Ethernet header)
#
# [instance methods]
#
# version -> int
#    version number of EtherIP (currently 1)
#
# to_pkt -> String
#    translate EtherIP packet to the bytestring.
#
# inspect -> String
#    translate EtherIP packet to human-readble string.
#
################################################################

require "spec_helper"

RSpec.describe Nwdiy::Packet::EtherIP do
  it "create an empty EtherIP" do
    pkt = Nwdiy::Packet::EtherIP.new
    expect(pkt.version).to be 1
  end

  it "creates an EtherIP packet with bytes" do
    e = "\x10\x00"
    dst = "\x00\x00\x0e\x00\x00\x01"
    src = "\x00\x00\x0e\x00\x00\x02"
    type = "\x08\x01"
    data = "Hello World"
    eip = Nwdiy::Packet::EtherIP.new(e + dst + src + type + data)
    expect(eip.data).to be_kind_of(Nwdiy::Packet::Ethernet)
    expect(eip.data.dst.to_pkt).to eq(dst)
    expect(eip.data.src.to_pkt).to eq(src)
    expect(eip.data.type).to eq(0x0801)
    expect(eip.data.data.to_pkt).to eq(data)
  end

  it "creates an EtherIP packet with hash" do
    dst = "\x00\x00\x0e\x00\x00\x01"
    src = "\x00\x00\x0e\x00\x00\x02"
    type = "\x08\x01"
    data = "Hello World"
    eip = Nwdiy::Packet::EtherIP.new(data: dst + src + type + data)
    expect(eip.data).to be_kind_of(Nwdiy::Packet::Ethernet)
    expect(eip.data.dst.to_pkt).to eq(dst)
    expect(eip.data.src.to_pkt).to eq(src)
    expect(eip.data.type).to eq(0x0801)
    expect(eip.data.data.to_pkt).to eq(data)
  end
end
