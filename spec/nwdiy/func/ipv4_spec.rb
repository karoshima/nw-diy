#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2018 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# with Apache-2 license.  check /LICENSE please.
################################################################
# IPv4 interface

require "spec_helper"

Thread.abort_on_exception = true

class Nwdiy::Func::IPv4
  def recvpktqlen
    @upq_upper.length
  end
end

RSpec.describe Nwdiy::Func::IPv4 do

  it 'can create IPv4 device' do
    ip1 = Nwdiy::Func::IPv4.new("ip1", local: "192.168.1.0/24")
    # it must be able to send/recv packets
    expect(ip1.respond_to?(:sendpkt)).to eq true
    expect(ip1.respond_to?(:recvpkt)).to eq true
    # it must be able to get sent packet, to push a received packets
    expect(ip1.respond_to?(:sendpkt)).to eq true
    expect(ip1.respond_to?(:sendpkt)).to eq true
  end

  it 'can create IPv4 device from an Ethernet' do
    eth2 = Nwdiy::Func::Ethernet.new("eth2")
    ip2 = eth2.ipv4("ip2", local: "192.168.2.1/24")
    expect(ip2.addr.inspect).to eq "192.168.2.1/24"
  end

  it 'can attach IPv4 device to an Ethernet device' do
    eth3 = Nwdiy::Func::Ethernet.new("eth3")
    ip3 = Nwdiy::Func::IPv4.new("ip3", local: "192.168.3.1/24")
    ip3.lower = eth3
  end

  it 'can check whether the packet comes to me or not' do
    ip4 = Nwdiy::Func::IPv4.new("ip4", local: "192.168.4.1/24")
    pkt4 = Nwdiy::Packet::IPv4.new(dst: "0.0.0.0")
    expect(ip4.forme?(pkt4)).to be true
    pkt4.dst = "192.168.3.255"
    expect(ip4.forme?(pkt4)).to be false
    pkt4.dst = "192.168.4.1"
    expect(ip4.forme?(pkt4)).to be true
    pkt4.dst = "192.168.4.2"
    expect(ip4.forme?(pkt4)).to be false
    pkt4.dst = "192.168.4.255"
    expect(ip4.forme?(pkt4)).to be true
    pkt4.dst = "224.1.1.1"
    expect(ip4.forme?(pkt4)).to be false
    ip4.join("224.1.1.1")
    expect(ip4.forme?(pkt4)).to be true
    ip4.leave("224.1.1.1")
    expect(ip4.forme?(pkt4)).to be false
    pkt4.dst = "255.255.255.255"
    expect(ip4.forme?(pkt4)).to be true
  end

  it 'can send IPv4 packet, and pop it from the lower side' do
    ip5 = Nwdiy::Func::IPv4.new("ip5", local: "192.168.5.1/24")
    pkt51 = Nwdiy::Packet::IPv4.new(dst: "1.1.1.1")
    ip5.sendpkt(pkt51)
    pkt52 = ip5.pop
  end

  it 'can send IPv4 data, and pop an IPv4 packet from the lower side' do
    ip6 = Nwdiy::Func::IPv4.new("ip6", local: "192.168.6.1/24")
    pkt61 = Nwdiy::Packet::UDP.new
    ip6.sendpkt("192.168.6.2", pkt61)
    pkt62 = ip6.pop
    expect(pkt62).to be_kind_of(Nwdiy::Packet::IPv4)
    expect(pkt62.src).to eq "192.168.6.1"
    expect(pkt62.dst).to eq "192.168.6.2"
    expect(pkt62.proto).to eq 17
    expect(pkt62.data).to be pkt61
  end

  it 'can send IPv4 packets, and pop an ARP and Ethernet Frame from the lower side of Ethernet' do
    eth7 = Nwdiy::Func::Ethernet.new("eth7")
    ip7 = eth7.ipv4("ip7", local: "192.168.7.1/24")
    pkt71 = Nwdiy::Packet::UDP.new
    ip7.sendpkt("192.168.7.2", pkt71)
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
    ip8 = eth8.ipv4("ip8", local: "192.168.8.1/24")
    pkt81 = Nwdiy::Packet::UDP.new
    ip8.sendpkt("192.168.8.2", pkt81)
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

  it 'can recv IPv4 packet to me, which are pushed from the lower side' do
    ip9 = Nwdiy::Func::IPv4.new("ip9", local: "192.168.9.1/24")
    pkt91 = Nwdiy::Packet::IPv4.new(src: "192.168.9.2", dst: "192.168.9.1")
    ip9.push(pkt91)
    pkt92, lower = ip9.recvpkt
    expect(pkt92).to eq pkt91
  end

  it 'monitors IPv4 packet with unknown proto, and not to me, which are pushed from the lower side' do
    ip10 = Nwdiy::Func::IPv4.new("ip10", local: "192.168.10.1/24")
    pkt101 = Nwdiy::Packet::IPv4.new(src: "192.168.10.2", dst: "192.168.10.3")
    ip10.push(pkt101)
    pkt102, lower = ip10.recvpkt
    expect(pkt102).to be pkt101
  end

  it 'monitors IPv4 packet with known proto, and not to me, which are pushed from the lower side' do
    ip11 = Nwdiy::Func::IPv4.new("ip10", local: "192.168.10.1/24")
    ip11[17] = 1 # dummy (Nwdiy::Packet::UDP is not yet implemented)
    pkt111 = Nwdiy::Packet::IPv4.new(src: "192.168.10.2", dst: "192.168.10.3")
    pkt111.data = Nwdiy::Packet::UDP.new
    ip11.push(pkt111)
    sleep 0.1
    expect(ip11.recvpktqlen).to be 0
  end

  it 'can recv IPv4 packet to us(broadcast), which are pushed from the lower side' do
    ip12 = Nwdiy::Func::IPv4.new("ip12", local: "192.168.12.1/24")
    pkt121 = Nwdiy::Packet::IPv4.new(src: "192.168.12.2", dst: "192.168.12.255")
    ip12.push(pkt121)
    pkt122, lower = ip12.recvpkt
    expect(pkt122).to eq pkt121
   end

  it 'can recv IPv4 packet to us(multicast), which are pushed from the lower side' do
    ip13 = Nwdiy::Func::IPv4.new("ip13", local: "192.168.13.1/24")
    ip13.join("224.0.0.5")
    pkt131 = Nwdiy::Packet::IPv4.new(src: "192.168.13.2", dst: "224.0.0.5")
    ip13.push(pkt131)
    pkt132, lower = ip13.recvpkt
    expect(pkt132).to eq pkt131
  end

  it 'ignores IPv4 packet not to me(multicast), which are pushed from the lower side' do
    ip14 = Nwdiy::Func::IPv4.new("ip14", local: "192.168.14.1/24")
    ip14.join("224.0.0.5")
    pkt141 = Nwdiy::Packet::IPv4.new(src: "192.168.14.2", dst: "224.0.0.6")
    ip14.push(pkt141)
    pkt142, lower = ip14.recvpkt
    expect(pkt142).to eq pkt141
  end

  # it 'can recv IPv4 packets which are pushed from the lower side of the Ethernet device' do
  # end

  # it 'can get the gateway for a destination' do
  # end

end
