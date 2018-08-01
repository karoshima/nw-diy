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
    eip = Nwdiy::Func::EtherIP.new(Nwdiy::Packet::IPv4Addr)
    skip('メソッドはあとで作る')
    # it must be able to send/recv packets
    expect(eip.respond_to?(:sendpkt)).to eq true
    expect(eip.respond_to?(:recvpkt)).to eq true
    # it must be able to get sent packets, able to push a received packets
    expect(eip.respond_to?(:push)).to eq true
    expect(eip.respond_to?(:pop)).to eq true
  end

  it 'can create Ethernet device from an EtherIP' do
    eip = Nwdiy::Func::EtherIP.new(Nwdiy::Packet::IPv4Addr)
    eth = eip["192.168.1.2"]
    expect(eth).to be_kind_of(Nwdiy::Func::Ethernet)
  end

  it 'can create Ethernet device from an IPv4 device' do
    ip1 = Nwdiy::Func::IPv4.new("ip1", local: "192.168.1.1/24")
    eth = ip1.etherip["192.168.1.2"]
    expect(eth).to be_kind_of(Nwdiy::Func::Ethernet)
    expect(eth.to_s).to eq "EtherIP(192.168.1.2)"
  end
end
