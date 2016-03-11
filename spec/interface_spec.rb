#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require 'nwdiy/interface'
require 'nwdiy/iplink'

describe NWDIY::IFP, 'を作るとき' do
  it 'インターフェース名として nil を与えたら、エラー' do
    expect do
      ifp = NWDIY::IFP.new()
    end.to raise_error(ArgumentError)
    expect do
      ifp = NWDIY::IFP.new(nil)
    end.to raise_error(ArgumentError)
  end

  it '実在するインターフェース名を与えたら、そのインターフェースを pcap で開く' do
    link = NWDIY::IPLINK.new
    lo = link['lo'] or link[0]
    ifp = NWDIY::IFP.new(lo)
    expect(ifp).not_to be_nil
  end

  it '実在しないインターフェース名を与えたら、ソケットファイルを作る' do
    ifp = NWDIY::IFP.new('abcde')
    expect(ifp).not_to be_nil
  end

  it '{type: :pcap, name: <ifp>} を与えたら、そのインターフェースを pcap で開く' do
    link = NWDIY::IPLINK.new
    lo = link['lo'] or link[0]
    ifp = NWDIY::IFP.new({type: :pcap, name: lo})
    expect(ifp).not_to be_nil
  end

  it '{type: :sock, name: <file>} を与えたら、ソケットファイルを作ってくる' do
    ifp = NWDIY::IFP.new({type: :sock, name: 'lo'})
    expect(ifp).not_to be_nil
  end

  it 'pcap にパケットを送ったら、インターフェースから出てくる' do
    link = NWDIY::IPLINK.new
    lo = link['enp0s9']
    ifp = NWDIY::IFP.new(lo)
    pkt = NWDIY::PKT::Ethernet.new
    pkt.dst = "ff-ff-ff-ff-ff-ff"
    pkt.data = NWDIY::PKT::IPv4.new
    pkt.data.proto = 89
    pkt.data.src = '127.0.0.1'
    pkt.data.dst = '127.255.255.255'
    pkt.data.data = "xxxxxxxxxxxxxxxx"
    expect(ifp.send(pkt)).to eq(pkt.bytesize)
  end

  it 'インターフェースにパケットを突っ込むと pcap から出てくる' do
    link = NWDIY::IPLINK.new
    lo = link['lo'] or link[0]
    ifp = NWDIY::IFP.new(lo)
    system("ping -c 3 #{lo.addr('IPv4')[0][:addr]} 2>&1 >/dev/null &");
    expect(ifp.recv.class).to eq(NWDIY::PKT::Ethernet)
  end

end
