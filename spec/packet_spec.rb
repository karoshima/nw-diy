#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require 'nwdiy/packet'

describe NwDiy::Packet, 'を作るとき' do
  it '中身のない Ethernet Frame を作って、あとから修正する' do
    eth = NwDiy::Packet::Ethernet.new
    expect(eth).not_to be nil
    eth.dst = "ff:ff:ff:ff:ff:ff"
    eth.data = data = "xxxxxxxxxx"
    expect(eth.dst.to_s).to be == "ff:ff:ff:ff:ff:ff"
    expect(eth.data.to_pkt).to be == data
    expect(eth.bytesize).to be == 14 + data.bytesize
    expect(eth.type).to be == 14 + data.bytesize
    # Ethertype を指定しないときは 802.3 フォーマットで
    # type 部が length になる
  end

  it '中身のない IPv4 packet を作って、あとから修正する' do
    ipv4 = NwDiy::Packet::IPv4.new
    expect(ipv4).not_to be nil
    ipv4.src = '127.0.0.1'
    ipv4.data = data = "xxxxxxxxxxxxxxxx"
    expect(ipv4.src.to_s).to be == '127.0.0.1'
    expect(ipv4.data.to_pkt).to be == data
    expect(ipv4.bytesize).to be == 20 + data.length
  end

  it 'IPv4 over Ethernet' do
    eth = NwDiy::Packet::Ethernet.new
    expect(eth).not_to be nil
    eth.data = ipv4 = NwDiy::Packet::IPv4.new
    expect(ipv4).not_to be nil
    data = "xxxxxxxxxxxxxxxx"
    ipv4.src = '127.0.0.1'
    ipv4.data = data
    expect(ipv4.src.to_s).to be == '127.0.0.1'
    expect(ipv4.data.to_pkt).to be == data
    expect(ipv4.bytesize).to be == 20 + data.length
    expect(eth.bytesize).to be == 34 + data.length
  end

  it 'ping を作る' do
    eth = NwDiy::Packet::Ethernet.new
    expect(eth).not_to be nil
    eth.data = NwDiy::Packet::IPv4.new
    expect(eth.type).to be == 0x0800
    expect(eth.data.class).to be NwDiy::Packet::IPv4
    eth.data.data = NwDiy::Packet::IP::ICMP4.new
    expect(eth.data.proto).to be 1
    expect(eth.data.data.class).to be NwDiy::Packet::IP::ICMP4
    eth.data.data.data = NwDiy::Packet::IP::ICMP::EchoRequest.new
    expect(eth.data.data.type).to be == 8
    expect(eth.data.data.data.class).to be NwDiy::Packet::IP::ICMP::EchoRequest
    eth.data.data.data.id = id = rand
    expect(eth.data.data.data.id).to be == id
  end

  it 'ping6' do
    eth = NwDiy::Packet::Ethernet.new
    expect(eth).not_to be nil
    eth.data = NwDiy::Packet::IPv6.new
    expect(eth.type).to be == 0x86dd
    expect(eth.data.class).to be NwDiy::Packet::IPv6
    eth.data.data = NwDiy::Packet::IP::ICMP6.new
    expect(eth.data.next).to be 58
    expect(eth.data.data.class).to be NwDiy::Packet::IP::ICMP6
    eth.data.data.data = NwDiy::Packet::IP::ICMP::EchoRequest.new
    expect(eth.data.data.type).to be == 128
    expect(eth.data.data.data.class).to be NwDiy::Packet::IP::ICMP::EchoRequest
    eth.data.data.data.id = id = rand
    expect(eth.data.data.data.id).to be == id
  end
end
