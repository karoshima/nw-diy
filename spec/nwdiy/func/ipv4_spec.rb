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
    ip11 = Nwdiy::Func::IPv4.new("ip11", local: "192.168.11.1/24")
    pkt11a = Nwdiy::Packet::IPv4.new(dst: "1.1.1.1")
    ip11.sendpkt(pkt11a)
    pkt11b = ip11.pop
  end

  it 'can send IPv4 data, and pop an IPv4 packet from the lower side' do
    ip12 = Nwdiy::Func::IPv4.new("ip12", local: "192.168.12.1/24")
    pkt12a = Nwdiy::Packet::UDP.new
    ip12.sendpkt("192.168.12.2", pkt12a)
    pkt12b = ip12.pop
    expect(pkt12b).to be_kind_of(Nwdiy::Packet::IPv4)
    expect(pkt12b.src).to eq "192.168.12.1"
    expect(pkt12b.dst).to eq "192.168.12.2"
    expect(pkt12b.proto).to eq 17
    expect(pkt12b.data).to be pkt12a
  end

  it 'can send IPv4 packets, and pop an ARP and Ethernet Frame from the lower side of Ethernet' do
    eth13 = Nwdiy::Func::Ethernet.new("eth13")
    ip13 = eth13.ipv4("ip13", local: "192.168.13.1/24")
    pkt13a = Nwdiy::Packet::UDP.new
    ip13.sendpkt("192.168.13.2", pkt13a)
    pkt13b = eth13.pop
    expect(pkt13b).to be_kind_of(Nwdiy::Packet::Ethernet)
    expect(pkt13b.dst).to eq "ff:ff:ff:ff:ff:ff"
    expect(pkt13b.type).to eq 0x0806
    expect(pkt13b.data).to be_kind_of(Nwdiy::Packet::ARP)
    expect(pkt13b.data.op).to eq 1
    expect(pkt13b.data.psnd).to eq "192.168.13.1"
    expect(pkt13b.data.ptgt).to eq "192.168.13.2"
  end

  it 'can send unresolved IPv4 packets when it receives ARP response' do
    eth14 = Nwdiy::Func::Ethernet.new("eth14")
    ip14 = eth14.ipv4("ip14", local: "192.168.14.1/24")
    pkt14a = Nwdiy::Packet::UDP.new
    ip14.sendpkt("192.168.14.2", pkt14a)
    pkt14b = eth14.pop
    expect(pkt14b).to be_kind_of(Nwdiy::Packet::Ethernet)
    arp142 = pkt14b.data
    expect(arp142).to be_kind_of(Nwdiy::Packet::ARP)
    pkt14b.src, pkt14b.dst = pkt14b.dst, pkt14b.src
    arp142.op = 2
    arp142.htgt = arp142.hsnd
    arp142.hsnd = Nwdiy::Packet::MacAddr.new(global: true)
    arp142.psnd, arp142.ptgt = arp142.ptgt, arp142.psnd
    eth14.push(pkt14b)
    pkt14c = eth14.pop
    expect(pkt14c).to be_kind_of(Nwdiy::Packet::Ethernet)
    expect(pkt14c.dst).to eq arp142.hsnd
    expect(pkt14c.data).to be_kind_of(Nwdiy::Packet::IPv4)
    expect(pkt14c.data.data).to be pkt14a
  end

  it 'can recv IPv4 packet to me, which are pushed from the lower side' do
    ip21 = Nwdiy::Func::IPv4.new("ip21", local: "192.168.21.1/24")
    pkt21a = Nwdiy::Packet::IPv4.new(src: "192.168.21.2", dst: "192.168.21.1")
    ip21.push(pkt21a)
    pkt21b, lower = ip21.recvpkt
    expect(pkt21b).to eq pkt21a
  end

  it 'monitors IPv4 packet with unknown proto, and not to me, which are pushed from the lower side' do
    ip22 = Nwdiy::Func::IPv4.new("ip22", local: "192.168.22.1/24")
    pkt22a = Nwdiy::Packet::IPv4.new(src: "192.168.22.2", dst: "192.168.22.3")
    ip22.push(pkt22a)
    pkt22b, lower = ip22.recvpkt
    expect(pkt22b).to be pkt22a
  end

  it 'monitors IPv4 packet with known proto, and not to me, which are pushed from the lower side' do
    ip23 = Nwdiy::Func::IPv4.new("ip10", local: "192.168.23.1/24")
    ip23[17] = 1 # dummy (Nwdiy::Packet::UDP is not yet implemented)
    pkt23a = Nwdiy::Packet::IPv4.new(src: "192.168.23.2", dst: "192.168.23.3")
    pkt23a.data = Nwdiy::Packet::UDP.new
    ip23.push(pkt23a)
    sleep 0.1
    expect(ip23.recvpktqlen).to be 0
  end

  it 'can recv IPv4 packet to us(broadcast), which are pushed from the lower side' do
    ip24 = Nwdiy::Func::IPv4.new("ip24", local: "192.168.24.1/24")
    pkt24a = Nwdiy::Packet::IPv4.new(src: "192.168.24.2", dst: "192.168.24.255")
    ip24.push(pkt24a)
    pkt24b, lower = ip24.recvpkt
    expect(pkt24b).to eq pkt24a
   end

  it 'can recv IPv4 packet to us(multicast), which are pushed from the lower side' do
    ip25 = Nwdiy::Func::IPv4.new("ip25", local: "192.168.25.1/24")
    ip25.join("224.0.0.5")
    pkt25a = Nwdiy::Packet::IPv4.new(src: "192.168.25.2", dst: "224.0.0.5")
    ip25.push(pkt25a)
    pkt25b, lower = ip25.recvpkt
    expect(pkt25b).to eq pkt25a
  end

  it 'ignores IPv4 packet not to me(multicast), which are pushed from the lower side' do
    ip26 = Nwdiy::Func::IPv4.new("ip26", local: "192.168.26.1/24")
    ip26.join("224.0.0.5")
    pkt26a = Nwdiy::Packet::IPv4.new(src: "192.168.26.2", dst: "224.0.0.6")
    ip26.push(pkt26a)
    pkt26b, lower = ip26.recvpkt
    expect(pkt26b).to eq pkt26a
  end

  it 'can recv IPv4 packets which are pushed from the lower side of the Ethernet device' do
    eth27 = Nwdiy::Func::Ethernet.new("eth27")
    ip27 = eth27.ipv4("ip27", local: "192.168.27.1/24")
    pkt27a = Nwdiy::Packet::Ethernet.new(
      dst: eth27.addr,
      data: Nwdiy::Packet::IPv4.new(
        dst: ip27.addr.addr,
        data: Nwdiy::Packet::UDP.new))
    eth27.push(pkt27a)
    pkt27b, lower = ip27.recvpkt
    expect(pkt27b).to eq pkt27a.data
  end

  it 'can get the gateway for a destination' do
    skip "It should have the routing function"
  end

end
