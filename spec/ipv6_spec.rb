#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require 'nwdiy/packet/ipv6'
require 'nwdiy/packet/ip/icmp6'

describe NwDiy::Packet::IPv6, 'を作るとき' do
  it '中身のない IPv6 packet を作って、あとから修正する' do
    ipv6 = NwDiy::Packet::IPv6.new
    expect(ipv6).not_to be nil
    ipv6.src = 'fe80::1'
    ipv6.data = data = "xxxxxxxxxxxxxxxx"
    expect(ipv6.src.to_s).to be == 'fe80::1'
    expect(ipv6.data.to_pkt).to be == data
    expect(ipv6.bytesize).to be == 40 + data.length
  end

  it 'データ長をいじったら length も追随する' do
    ipv6 = NwDiy::Packet::IPv6.new
    expect(ipv6).not_to be nil
    ipv6.src = 'fe80::2'
    ipv6.data = data = "xxxxxxxxxxxxxxxx"
    expect(ipv6.length).to be == 56
    ipv6.data = data = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    expect(ipv6.length).to be == 72
  end

  it '@auto_compile = false したら追随しない' do
    ipv6 = NwDiy::Packet::IPv6.new
    expect(ipv6).not_to be nil
    ipv6.auto_compile = false
    ipv6.src = 'fe80::2'
    ipv6.data = data = "xxxxxxxxxxxxxxxx"
    expect(ipv6.length).to be == 40
    ipv6.data = data = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    expect(ipv6.length).to be == 40
  end

  it 'データを付けたら next が変わる' do
    ipv6 = NwDiy::Packet::IPv6.new
    expect(ipv6).not_to be nil
    expect(ipv6.next).to be == 0
    ipv6.data = NwDiy::Packet::IP::ICMP6.new
    expect(ipv6.next).to be == 58
  end

  it '@auto_compile = false したら変わらない' do
    ipv6 = NwDiy::Packet::IPv6.new
    expect(ipv6).not_to be nil
    ipv6.auto_compile = false
    expect(ipv6.next).to be == 0
    ipv6.data = NwDiy::Packet::IP::ICMP6.new
    expect(ipv6.next).to be == 0
  end
end
