#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2018 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# with Apache-2 license.  check /LICENSE please.
################################################################
# Ethernet interface

require "spec_helper"

Thread.abort_on_exception = true

class Nwdiy::Func::Ethernet
  def recvpktqlen
    @upq_upper.length
  end
end

RSpec.describe Nwdiy::Func::EtherIP do

  it 'can create EtherIP device' do
    # it must be able to get sent packets, able to push a received packets
    eip = Nwdiy::Func::EtherIP.new(Nwdiy::Packet::IPv4Addr)
    expect(eip.respond_to?(:push)).to eq true
    expect(eip.respond_to?(:pop)).to eq true
    # it must be able to send/recv packets
    eip1 = eip["192.168.254.2"]
    expect(eip1.respond_to?(:sendpkt)).to eq true
    expect(eip1.respond_to?(:recvpkt)).to eq true
  end

  it 'can create Ethernet device from an EtherIP' do
    eip = Nwdiy::Func::EtherIP.new(Nwdiy::Packet::IPv4Addr)
    eth = eip["192.168.1.2"]
    expect(eth).to be_kind_of(Nwdiy::Func::Ethernet)
  end

  it 'can create Ethernet device from an IPv4 device' do
    ip = Nwdiy::Func::IPv4.new("ip1", local: "192.168.1.1/24")
    eth = ip.etherip["192.168.1.2"]
    expect(eth).to be_kind_of(Nwdiy::Func::Ethernet)
    expect(eth.to_s).to eq "EtherIP(192.168.1.2)"
  end

  it 'can check whether the packet comes to me or not' do
    # ip.forme?() can check
    # (1) the packet comes to me?
    # ip.etherip.forme?() can check
    # (2) the packet comes from the peer?
    # (3) the IP packet has EtherIP Header?
    # (4) the EtherIP packet has Ethernet?
    ip = Nwdiy::Func::IPv4.new("ip", local: "192.168.1.1/24")
    eip = ip.etherip
    eth = eip["192.168.1.2"]
    expect(eip.has_key?("192.168.1.2")).to be true
    pkt = Nwdiy::Packet::IPv4.new(dst: "192.168.1.1")
    expect(ip.forme?(pkt)).to be true
    expect(eip.forme?(pkt.data, pkt)).to be false
    pkt.data = Nwdiy::Packet::EtherIP.new
    expect(eip.forme?(pkt.data, pkt)).to be false
    pkt.src = "192.168.1.2"
    expect(eip.forme?(pkt.data, pkt)).to be false
    pkt.data.data = Nwdiy::Packet::Ethernet.new
    expect(eip.forme?(pkt.data, pkt)).to be true
    pkt.src = "192.168.1.3"
    expect(eip.forme?(pkt.data, pkt)).to be false
  end

  it 'can send Ethernet frame, and pop it from the lower side' do
    eip01 = Nwdiy::Func::EtherIP.new(Nwdiy::Packet::IPv4Addr)
    eip02 = eip01["192.168.1.1"]
    expect(eip02).to be_kind_of(Nwdiy::Func::Ethernet)
    pkt01a = Nwdiy::Packet::Ethernet.new
    eip02.sendpkt(pkt01a)
    pkt01b = eip01.pop
    expect(pkt01b).to be_kind_of(Nwdiy::Packet::IPv4)
    expect(pkt01b.dst).to eq "192.168.1.1"
    expect(pkt01b.data).to be_kind_of(Nwdiy::Packet::EtherIP)
    expect(pkt01b.data.data).to be pkt01a
  end

  it 'can recv an Ethernet frame, which is pushd from the lower side' do
    ip01 = Nwdiy::Func::IPv4.new("ip01", local: "192.168.1.1/24")
    eip02 = ip01.etherip["192.168.2.2"]
    pkt = Nwdiy::Packet::IPv4.new

    ip01.push(pkt)
    sleep 0.1
    expect(eip02.recvpktqlen).to be 0

    pkt.dst = ip01.addr.addr
    ip01.push(pkt)
    sleep 0.1
    expect(eip02.recvpktqlen).to be 0

    pkt.src = "192.168.2.2"
    ip01.push(pkt)
    sleep 0.1
    expect(eip02.recvpktqlen).to be 0

    pkt.data = Nwdiy::Packet::EtherIP.new
    ip01.push(pkt)
    sleep 0.1
    expect(eip02.recvpktqlen).to be 0

    pkt.data.data = Nwdiy::Packet::Ethernet.new
    ip01.push(pkt)
    sleep 0.1
    expect(eip02.recvpktqlen).to be 1
    expect(eip02.recvpkt).to eq [pkt.data.data, [pkt, pkt.data]]
  end

  it 'can pipe Ethernet and EtherIP' do
    #                 Ethernet ------- Ethernet
    #                    |                |
    # 192.168.0.1 => 192.168.0.2     192.168.0.3 => 192.168.0.4

    skip "pipe for EtherIP"

    ip2 = Nwdiy::Func::IPv4.new("ip2", local: "192.168.0.2/24")
    ip3 = Nwdiy::Func::IPv4.new("ip3", local: "192.168.0.3/24")
    eth21 = ip2.etherip["192.168.0.1"] # Ethernet: EtherIP peer is 192.168.0.1
    eth34 = ip3.etherip["192.168.0.4"] # Ethernet: Ethernet peer is 192.168.0.4
    eth21 | eth34

    pkt1 = Nwdiy::Packet::IPv4.new
    pkt1.src = "192.168.0.1"
    pkt1.dst = "192.168.0.2"
    pkt1.data = Nwdiy::Packet::EtherIP.new
    pkt1.data.data = Nwdiy::Packet::Ethernet.new

    ip2.push(pkt1)
    pkt2 = ip3.pop

    expect(pkt2.src).to eq "192.168.0.3"
    expect(pkt2.dst).to eq "192.168.0.4"
    expect(pkt2.data).to be_kind_of Nwdiy::Packet:EtherIP
    expect(pkt2.data.data).to be pkt1.data.data
  end
end
