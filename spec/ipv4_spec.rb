#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require 'nwdiy/packet/ipv4'
require 'nwdiy/packet/ip/icmp4'

describe NwDiy::Packet::IPv4, 'を作るとき' do
  it '中身のない IPv4 packet を作って、あとから修正する' do
    ipv4 = NwDiy::Packet::IPv4.new
    expect(ipv4).not_to be nil
    ipv4.src = '127.0.0.1'
    ipv4.data = data = "xxxxxxxxxxxxxxxx"
    expect(ipv4.src.to_s).to be == '127.0.0.1'
    expect(ipv4.data.to_pkt).to be == data
    expect(ipv4.bytesize).to be == 20 + data.length
  end

  it 'データ長をいじったら length も追随する' do
    ipv4 = NwDiy::Packet::IPv4.new
    expect(ipv4).not_to be nil
    ipv4.src = '127.0.0.1'
    ipv4.data = data = "xxxxxxxxxxxxxxxx"
    expect(ipv4.length).to be == 36
    ipv4.data = data = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    expect(ipv4.length).to be == 52
  end

  it '@auto_compile を false にしたら追随しない' do
    ipv4 = NwDiy::Packet::IPv4.new
    expect(ipv4).not_to be nil
    ipv4.auto_compile = false
    ipv4.src = '127.0.0.1'
    ipv4.data = data = "xxxxxxxxxxxxxxxx"
    expect(ipv4.length).to be == 20
    ipv4.data = data = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    expect(ipv4.length).to be == 20
  end

  it 'ttl を減算したら cksum も追随する' do
    ipv4 = NwDiy::Packet::IPv4.new
    expect(ipv4).not_to be nil
    ipv4.id = 1
    ipv4.ttl = 64
    ipv4.src = '127.0.0.1'
    ipv4.data = data = "xxxxxxxxxxxxxxxx"
    expect(ipv4.cksum).to be == 0x3815 # 勝手にちゃんと計算されるし
    ipv4.ttl -= 1                      # TTL 減算したら
    expect(ipv4.cksum).to be == 0x3915 # 勝手にちゃんと計算されてること
  end

  it '@auto_compile を false にしたら追随しない' do
    ipv4 = NwDiy::Packet::IPv4.new
    expect(ipv4).not_to be nil
    ipv4.auto_compile = false
    ipv4.id = 1
    ipv4.ttl = 64
    ipv4.src = '127.0.0.1'
    ipv4.data = data = "xxxxxxxxxxxxxxxx"
    expect(ipv4.cksum).to be == 0 # 計算されてない
    ipv4.ttl -= 1
    expect(ipv4.cksum).to be == 0 # 計算されてない
  end

  it 'データを付けたら proto が変わる' do
    ipv4 = NwDiy::Packet::IPv4.new
    expect(ipv4).not_to be nil
    expect(ipv4.proto).to be == 0
    ipv4.data = NwDiy::Packet::IP::ICMP4.new
    expect(ipv4.proto).to be == 1
  end

  it '@auto_compile を false にしたら変わんない' do
    ipv4 = NwDiy::Packet::IPv4.new
    expect(ipv4).not_to be nil
    ipv4.auto_compile = false
    expect(ipv4.proto).to be == 0
    ipv4.data = NwDiy::Packet::IP::ICMP4.new
    expect(ipv4.proto).to be == 0
  end
end
