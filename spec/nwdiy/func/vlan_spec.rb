#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2018 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# with Apache-2 license.  check /LICENSE please.
################################################################
# Ethernet interface

require "spec_helper"

Thread.abort_on_exception = true

RSpec.describe Nwdiy::Func::VLAN do
  it "#initialize" do
    vlan = Nwdiy::Func::VLAN.new("vlanX")
    pkt11 = Nwdiy::Packet::Ethernet.new(data: Nwdiy::Packet::IPv4.new)
    expect(pkt11).not_to be nil
    expect(vlan.newid(1)).to be_kind_of(Nwdiy::Func::VLANID)
    expect(vlan[1].respond_to?(:recv)).to eq true
    # flow down
    vlan[1].send(pkt11)
    pkt12 = vlan.pop
    expect(pkt12).to be_kind_of(Nwdiy::Packet::Ethernet)
    expect(pkt12.src).to eq "00:00:00:00:00:00"
    expect(pkt12.data).to be_kind_of(Nwdiy::Packet::VLAN)
    expect(pkt12.data.vid).to eq 1
    expect(pkt12.data.data).to be_kind_of(Nwdiy::Packet::IPv4)
    # flow up
    vlan.push(pkt12)
    pkt13, = vlan[1].recv
    expect(pkt13).to be_kind_of(Nwdiy::Packet::Ethernet)
    expect(pkt13.data).to be_kind_of(Nwdiy::Packet::IPv4)
  end

  it "is created from a ethernet" do
    eth2 = Nwdiy::Func::Ethernet.new("eth2")
    expect(eth2).not_to be nil
    vlan2 = eth2.vlan
    expect(vlan2).to be_kind_of(Nwdiy::Func::VLAN)
    # flow down
    pkt21 = Nwdiy::Packet::Ethernet.new(
      data: Nwdiy::Packet::IPv4.new)
    vlan2.newid(2)
    expect(vlan2[2]).to be_kind_of(Nwdiy::Func::VLANID)
    vlan2[2].send(pkt21)
    pkt22 = eth2.pop
    expect(pkt22).to be_kind_of(Nwdiy::Packet::Ethernet)
    expect(pkt22.src).to eq eth2.addr # different from the above
    expect(pkt22.data).to be_kind_of(Nwdiy::Packet::VLAN)
    expect(pkt22.data.vid).to eq 2
    expect(pkt22.data.data).to be_kind_of(Nwdiy::Packet::IPv4)
    # flow up
    eth2.push(pkt22)
    pkt23, = vlan2[2].recv
    expect(pkt23).to be_kind_of(Nwdiy::Packet::Ethernet)
    expect(pkt23.data).to be_kind_of(Nwdiy::Packet::IPv4)
  end
end
