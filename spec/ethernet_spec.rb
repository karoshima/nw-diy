#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require 'nwdiy/packet/ethernet'

describe NwDiy::Packet::Ethernet, 'を使うとき' do
  it '中身のない Ethernet パケットを作って、あとから修正する' do
    eth = NwDiy::Packet::Ethernet.new
    expect(eth).not_to be nil
    eth.dst = 'FF:FF:FF:FF:FF:FF'
    eth.src = '00:00:00:00:00:01'
    eth.type = 0x0801
    eth.data = data = 'xxxx'
    expect(eth.dst.to_s).to be == "ff:ff:ff:ff:ff:ff"
    expect(eth.data.to_pkt).to be == data
    expect(eth.type).to be == 0x0801
    expect(eth.bytesize).to be == 18
  end

  it '中身のある Ethernet パケットを作って、あとから修正する' do
    eth = NwDiy::Packet::Ethernet.new("\xff\xff\xff\xff\xff\xff\0\0\0\0\0\1\x08\x01xxxx")
    expect(eth).not_to be nil
    expect(eth.dst.to_s).to be == "ff:ff:ff:ff:ff:ff"
    expect(eth.data.to_pkt).to be == "xxxx"
    expect(eth.type).to be == 0x0801
    expect(eth.bytesize).to be == 18
  end

  it 'パケット種別を変えて、type が変わることを確認する' do
    eth = NwDiy::Packet::Ethernet.new
    eth.data = NwDiy::Packet::IPv4.new
    expect(eth.type).to be == 0x0800
    eth.data = NwDiy::Packet::IPv6.new
    expect(eth.type).to be == 0x86dd
  end
end
