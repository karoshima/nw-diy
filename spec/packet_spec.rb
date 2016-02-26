#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require 'nwdiy/packet'

describe NWDIY::PKT, 'を作るとき' do
  it '中身のない Ethernet Frame を作る' do
    eth = NWDIY::PKT::Ethernet.new
    expect(eth).not_to be nil
  end

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
end
