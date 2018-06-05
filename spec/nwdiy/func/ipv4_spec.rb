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
  it 'init' do
    ip41 = Nwdiy::Func::IPv4.new("ip41", local: "192.168.1.1/24")
    pkt11 = Nwdiy::Packet::ICMP4.new
    ip41.arp["192.168.2.2"] = "00:00:00:00:00:22"
    expect(ip41.respond_to?(:sendpkt)).to eq true
    ip41.sendpkt("192.168.2.2", pkt11)
    pkt12 = ip41.pop
    expect(pkt12).to be_kind_of(Nwdiy::Packet::IPv4)
    expect(pkt12.dst).to eq "192.168.2.2"
    expect(pkt12.src).to eq "192.168.1.1"
    expect(pkt12.proto).to eq 1
    expect(pkt12.data).to eq pkt41
  end
end
