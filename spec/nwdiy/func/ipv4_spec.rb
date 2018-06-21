#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2018 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# with Apache-2 license.  check /LICENSE please.
################################################################
# IPv4 interface

require "spec_helper"

Thread.abort_on_exception = true

RSpec.describe Nwdiy::Func::IPv4 do

  it 'can create IPv4 device' do
    ip41 = Nwdiy::Func::IPv4.new("ip41", local: "192.168.1.0/24")
    # it must be able to send/recv packets
    expect(ip41.respond_to?(:sendpkt)).to eq true
    expect(ip41.respond_to?(:recvpkt)).to eq true
    # it must be able to get sent packet, to push a received packets
    expect(ip41.respond_to?(:sendpkt)).to eq true
    expect(ip41.respond_to?(:sendpkt)).to eq true
  end

  it 'can create IPv4 device from an Ethernet' do
    eth2 = Nwdiy::Func::Ethernet.new("eth2")
    ip42 = eth2.ipv4("ip42", local: "192.168.2.1/24")
    expect(ip42.addr.inspect).to eq "192.168.2.1/24"
  end

  it 'can attach IPv4 device to an Ethernet device' do
    eth3 = Nwdiy::Func::Ethernet.new("eth3")
    ip43 = Nwdiy::Func::IPv4.new("ip43", local: "192.168.3.1/24")
    ip43.lower = eth3
  end

  it 'can check whether the packet comes to me or not' do
    ip44 = Nwdiy::Func::IPv4.new("ip44", local: "192.168.4.1/24")
    pkt4 = Nwdiy::Packet::IPv4.new(dst: "0.0.0.0")
    expect(ip44.forme?(pkt4)).to be true
    pkt4.dst = "192.168.3.255"
    expect(ip44.forme?(pkt4)).to be false
    pkt4.dst = "192.168.4.1"
    expect(ip44.forme?(pkt4)).to be true
    pkt4.dst = "192.168.4.2"
    expect(ip44.forme?(pkt4)).to be false
    pkt4.dst = "192.168.4.255"
    expect(ip44.forme?(pkt4)).to be true
    pkt4.dst = "224.1.1.1"
    expect(ip44.forme?(pkt4)).to be false
    ip44.join("224.1.1.1")
    expect(ip44.forme?(pkt4)).to be true
    ip44.leave("224.1.1.1")
    expect(ip44.forme?(pkt4)).to be false
    pkt4.dst = "255.255.255.255"
    expect(ip44.forme?(pkt4)).to be true
  end

  it 'can send IPv4 packet, and pop it from the lower side' do
    ip45 = Nwdiy::Func::IPv4.new("ip45", local: "192.168.5.1/24")
    pkt51 = Nwdiy::Packet::IPv4.new(dst: "1.1.1.1")
    ip45.sendpkt(pkt51)
    pkt52 = ip45.pop
  end

  it 'can send IPv4 data, and pop an IPv4 packet from the lower side' do
    ip46 = Nwdiy::Func::IPv4.new("ip46", local: "192.168.6.1/24")
    pkt61 = Nwdiy::Packet::UDP.new
    ip46.sendpkt("192.168.6.2", pkt61)
    pkt62 = ip46.pop
    expect(pkt62).to be_kind_of(Nwdiy::Packet::IPv4)
    expect(pkt62.src).to eq "192.168.6.1"
    expect(pkt62.dst).to eq "192.168.6.2"
    expect(pkt62.proto).to eq 17
    expect(pkt62.data).to be pkt61
  end

  it 'can send IPv4 packets, and pop an ARP and Ethernet Frame from the lower side of Ethernet' do
    eth7 = Nwdiy::Func::Ethernet.new("eth7")
    ip47 = eth7.ipv4("ip47", local: "192.168.7.1/24")
    pkt71 = Nwdiy::Packet::UDP.new
    ip47.sendpkt("192.168.7.2", pkt71)
    pkt72 = eth7.pop
    expect(pkt72).to be_kind_of(Nwdiy::Packet::Ethernet)
    expect(pkt72.dst).to eq "ff:ff:ff:ff:ff:ff"
    expect(pkt72.type).to eq 0x0806
    expect(pkt72.data).to be_kind_of(Nwdiy::Packet::ARP)
    expect(pkt72.data.op).to eq 1
    expect(pkt72.data.psnd).to eq "192.168.7.1"
    expect(pkt72.data.ptgt).to eq "192.168.7.2"
  end

  it 'can send unresolved IPv4 packets when it receives ARP response' do
    eth8 = Nwdiy::Func::Ethernet.new("eth8")
    ip48 = eth8.ipv4("ip48", local: "192.168.8.1/24")
    pkt81 = Nwdiy::Packet::UDP.new
    ip48.sendpkt("192.168.8.2", pkt81)
    pkt82 = eth8.pop
    expect(pkt82).to be_kind_of(Nwdiy::Packet::Ethernet)
    arp82 = pkt82.data
    expect(arp82).to be_kind_of(Nwdiy::Packet::ARP)
    pkt82.src, pkt82.dst = pkt82.dst, pkt82.src
    arp82.op = 2
    arp82.htgt = arp82.hsnd
    arp82.hsnd = Nwdiy::Packet::MacAddr.new(global: true)
    arp82.psnd, arp82.ptgt = arp82.ptgt, arp82.psnd
    eth8.push(pkt82)
    pkt83 = eth8.pop
    expect(pkt83).to be_kind_of(Nwdiy::Packet::Ethernet)
    expect(pkt83.dst).to eq arp82.hsnd
    expect(pkt83.data).to be_kind_of(Nwdiy::Packet::IPv4)
    expect(pkt83.data.data).to be pkt81
  end

  # it 'can recv IPv4 packets which are pushed from the lower side' do
  # end

  # it 'can recv IPv4 packets which are pushed from the lower side of the Ethernet device' do
  # end

  # it 'can get the gateway for a destination' do
  # end

end
