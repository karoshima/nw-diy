#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require 'nwdiy/packet'

describe NWDIY::PKT, 'を作るとき' do
  it '中身のない Ethernet Frame を作って、あとから修正する' do
    eth = NWDIY::PKT::Ethernet.new
    expect(eth).not_to be nil
    data = "xxxxxxxxxx"
    eth.dst = "ff:ff:ff:ff:ff:ff"
    eth.data = data
    expect(eth.dst.to_s).to be == "ff:ff:ff:ff:ff:ff"
    expect(eth.data.to_pkt).to be == data
    expect(eth.length).to be == 14 + data.length
    expect(eth.type).to be == data.length
    # Ethertype を指定しないときは 802.3 フォーマットで
    # type 部が length になる
  end

  it '中身のない IPv4 packet を作って、あとから修正する' do
    ipv4 = NWDIY::PKT::IPv4.new
    expect(ipv4).not_to be nil
    data = "xxxxxxxxxxxxxxxx"
    ipv4.src = '127.0.0.1'
    ipv4.data = data
    expect(ipv4.src.to_s).to be == '127.0.0.1'
    expect(ipv4.data.to_pkt).to be == data
    expect(ipv4.length).to be == 20 + data.length
  end

  it 'IPv4 over Ethernet' do
    eth = NWDIY::PKT::Ethernet.new
    expect(eth).not_to be nil
    eth.data = ipv4 = NWDIY::PKT::IPv4.new
    expect(ipv4).not_to be nil
    data = "xxxxxxxxxxxxxxxx"
    ipv4.src = '127.0.0.1'
    ipv4.data = data
    expect(ipv4.src.to_s).to be == '127.0.0.1'
    expect(ipv4.data.to_pkt).to be == data
    expect(ipv4.length).to be == 20 + data.length
    expect(eth.length).to be == 34 + data.length
  end
end
