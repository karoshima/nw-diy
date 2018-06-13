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

  # it 'can send IPv4 packet, and pop it from the lower side' do
  #   ip45 = Nwdiy::Func::IPv4.new("ip45", local: "192.168.5.1/24")
  #   pkt51 = Nwdiy::Packet::IPv4.new
  #   ip45.sendpkt(pkt51)
  #   pkt52 = ip45.pop
  #   expect(pkt52).to be pkt51
  # end

  # it 'can send IPv4 data, and pop an IPv4 packet from the lower side' do
  #   ip46 = Nwdiy::Func::IPv4.new("ip46", local: "192.168.6.1/24")
  #   pkt61 = Nwdiy::Packet::ICMP4.new
  #   ip46.sendpkt("192.168.6.2", pkt61)
  #   pkt62 = ip46.pop
  #   expect(pkt62.src).to eq "192.168.6.1"
  #   expect(pkt62.dst).to eq "192.168.6.2"
  #   expect(pkt62.proto).to eq 1
  #   expect(pkt62.data).to be pkt61
  # end

  # it 'can send IPv4 packets, and pop an ARP and Ethernet Frame from the lower side of Ethernet' do
  # end

  # it 'can recv IPv4 packets which are pushed from the lower side' do
  # end

  # it 'can recv IPv4 packets which are pushed from the lower side of the Ethernet device' do
  # end

end
