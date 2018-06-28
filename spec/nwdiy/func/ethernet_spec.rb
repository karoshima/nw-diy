#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2018 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# with Apache-2 license.  check /LICENSE please.
################################################################
# Ethernet interface

require "spec_helper"

Thread.abort_on_exception = true

RSpec.describe Nwdiy::Func::Ethernet do
  # it can create Ethernet device
  it 'init' do
    eth0 = Nwdiy::Func::Ethernet.new("eth0")
    expect(eth0).not_to be nil
    # it must be able to send/recv packets
    expect(eth0.respond_to?(:sendpkt)).to eq true
    expect(eth0.respond_to?(:recvpkt)).to eq true
    # it must be able to get sent packet, to push a received packets
    expect(eth0.respond_to?(:sendpkt)).to eq true
    expect(eth0.respond_to?(:sendpkt)).to eq true
  end

  it 'can check whether the packet comes to me or not' do
    eth = Nwdiy::Func::Ethernet.new("eth")
    pkt = Nwdiy::Packet::Ethernet.new
    pkt.dst = Nwdiy::Packet::MacAddr.new(global: true)
    expect(eth.forme?(pkt)).to be false
    pkt.dst = eth.addr
    expect(eth.forme?(pkt)).to be true
    pkt.dst = "ff:ff:ff:ff:ff:ff"
    expect(eth.forme?(pkt)).to be true
    pkt.dst = "ff:ee:dd:cc:bb:aa"
    expect(eth.forme?(pkt)).to be false
    eth.join("ff:ee:dd:cc:bb:aa")
    expect(eth.forme?(pkt)).to be true
    eth.leave("ff:ee:dd:cc:bb:aa")
    expect(eth.forme?(pkt)).to be false
  end

  it 'can send ethenet frame, and pop it' do
    eth1 = Nwdiy::Func::Ethernet.new("eth1")
    pkt11 = Nwdiy::Packet::Ethernet.new(dst: "00:00:11:11:22:22",
                                        data: Nwdiy::Packet::IPv4.new)
    eth1.sendpkt(pkt11)
    pkt12 = eth1.pop
    expect(pkt12).to be_kind_of(Nwdiy::Packet::Ethernet)
    expect(pkt12).to be pkt11
    pkt12.dst, pkt12.src = pkt12.src, pkt12.dst
    eth1.push(pkt12)
    pkt13, lower = eth1.recvpkt
    expect(pkt13).to eq pkt11
  end

  it 'can send data, and pop an Ethernet frame' do
    eth2 = Nwdiy::Func::Ethernet.new("eth2")
    pkt21 = Nwdiy::Packet::IPv4.new
    eth2.sendpkt("00:00:11:11:33:33", pkt21)
    pkt22 = eth2.pop
    expect(pkt22).to be_kind_of(Nwdiy::Packet::Ethernet)
    expect(pkt22.data).to be pkt21
    pkt22.dst, pkt22.src = pkt22.src, pkt22.dst
    eth2.push(pkt22)
    pkt23, lower = eth2.recvpkt
    expect(pkt23.data).to eq pkt21
  end

  
end
