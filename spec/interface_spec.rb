#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require 'nwdiy/interface'
require 'nwdiy/iplink'

describe NwDiy::Interface, 'を作るとき' do
  it 'インターフェース名として nil を与えたら、エラー' do
    expect do
      ifp = NwDiy::Interface.new()
    end.to raise_error(ArgumentError)
    expect do
      ifp = NwDiy::Interface.new(nil)
    end.to raise_error(ArgumentError)
  end

  it '実在するインターフェース名を与えたら、そのインターフェースを pcap で開く' do
    link = NwDiy::IpLink.new
    lo = link['lo'] or link[0]
    ifp = NwDiy::Interface.new(lo)
    expect(ifp).not_to be_nil
  end

  it '実在しないインターフェース名を与えたら、ソケットファイルを作る' do
    ifp = NwDiy::Interface.new('abcde')
    expect(ifp).not_to be_nil
  end

  it '{type: :pcap, name: <ifp>} を与えたら、そのインターフェースを pcap で開く' do
    link = NwDiy::IpLink.new
    lo = link['lo'] or link[0]
    ifp = NwDiy::Interface.new({type: :pcap, name: lo})
    expect(ifp).not_to be_nil
  end

  it '{type: :sock, name: <file>} を与えたら、ソケットファイルを作ってくる' do
    ifp = NwDiy::Interface.new({type: :sock, name: 'lo'})
    expect(ifp).not_to be_nil
  end

  it 'pcap にパケットを送ったら、インターフェースから出てくる' do
    link = NwDiy::IpLink.new
    lo = link['lo']
    ifp = NwDiy::Interface.new(lo)
    pkt = NwDiy::Packet::Ethernet.new
    pkt.dst = "ff-ff-ff-ff-ff-ff"
    pkt.data = NwDiy::Packet::IPv4.new
    pkt.data.proto = 89
    pkt.data.src = '127.0.0.1'
    pkt.data.dst = '127.255.255.255'
    pkt.data.data = "xxxxxxxxxxxxxxxx"
    expect(ifp.send(pkt)).to eq(pkt.bytesize)
  end

  it 'インターフェースにパケットを突っ込むと pcap から出てくる' do
    link = NwDiy::IpLink.new
    lo = link['lo'] or link[0]
    ifp = NwDiy::Interface.new(lo)
    system("ping -c 3 #{lo.addr('IPv4')[0][:addr]} 2>&1 >/dev/null &");
    expect(ifp.recv.class).to eq(NwDiy::Packet::Ethernet)
  end

end
