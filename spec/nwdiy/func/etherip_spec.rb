#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2018 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# with Apache-2 license.  check /LICENSE please.
################################################################
# Ethernet interface

require "spec_helper"

Thread.abort_on_exception = true

RSpec.describe Nwdiy::Func::EtherIP do
  it 'can create EtherIP device' do
    eip01 = Nwdiy::Func::EtherIP.new("eip01")
    # it must be able to send/recv packets
    expect(eip01.respond_to?(:sendpkt)).to eq true
    expect(eip01.respond_to?(:recvpkt)).to eq true
    # it must be able to get sent packet, to push a received packets
    expect(eip01.respond_to?(:push)).to eq true
    expect(eip01.respond_to?(:pop)).to eq true
  end

  it 'can create EtherIP device from an IPv4' do
    ip02 = Nwdiy::Func::IPv4.new("ip02", local: "192.168.2.1/24")
    eip02 = ip02.etherip
    # it must be able to send/recv packets
    expect(eip02.respond_to?(:sendpkt)).to eq true
    expect(eip02.respond_to?(:recvpkt)).to eq true
    # it must be able to get sent packet, to push a received packets
    expect(eip02.respond_to?(:push)).to eq true
    expect(eip02.respond_to?(:pop)).to eq true
  end

  it 'can attach EtherIP device to an IPv4 device' do
    eip = Nwdiy::Func::EtherIP.new("eip")
    eth = eip.ethernet("eth")
    expect(eth).to be_kind_of(Nwdiy::Func::Ethernet)
  end

  it 'can attach Ethernet device to an EtherIP device' do
    ip = Nwdiy::Func::IPv4.new("ip", local: "192.168.1.1/24")
    eip = ip.etherip("eip")
    eth = eip.ethernet("eth")
    expect(eth).to be_kind_of(Nwdiy::Func::Ethernet)
  end

  it 'can check whether the packet comes to me or not' do
    ip = Nwdiy::Func::IPv4.new("ip", local: "192.168.1.1/24")
    eip = ip.etherip("eip", dst: "192.168.2.2")
  end

  it 'can send EtherIP frame, and pop it from the lower side' do
    eip = Nwdiy::Func::EtherIP.new("eip")
    pkt1 = Nwdiy::Packet::EtherIP.new(data: Nwdiy::Packet::Ethernet.new)
    eip.sendpkt(pkt1)
    pkt2 = eip.pop
    expect(pkt2).to be_kind_of(Nwdiy::Packet::EtherIP)
    expect(pkt2).to be pkt1
  end

  it 'can recv EtherIP frame, which are pushed from the lower side' do
    eip = Nwdiy::Func::EtherIP.new("eip")
    pkt1 = Nwdiy::Packet::EtherIP.new
    eip.push(pkt1)
    pkt2, lower = eip.recvpkt
    expect(pkt2).to eq pkt1
  end
end
