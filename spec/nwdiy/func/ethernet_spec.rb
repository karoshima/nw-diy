#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2018 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# with Apache-2 license.  check /LICENSE please.
################################################################
# Ethernet interface

require "spec_helper"

RSpec.describe Nwdiy::Func::Ethernet do
  it '#initialize' do
    eth0 = Nwdiy::Func::Ethernet.new("eth0")
    expect(eth0).not_to be nil
    pkt1 = Nwdiy::Packet::Ethernet.new
    expect(pkt1).not_to be nil
    expect(eth0.respond_to?(:sendup)).to eq true
    eth0.sendup(pkt1)
    pkt2 = eth0.recvup
    expect(pkt2).to be pkt1
    eth0.senddown(pkt1)
    pkt2 = eth0.recvdown
    expect(pkt2).to be pkt1
  end
end
