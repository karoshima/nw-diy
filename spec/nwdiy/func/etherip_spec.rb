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
end
