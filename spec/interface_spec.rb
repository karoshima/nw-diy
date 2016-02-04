#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require "interface"

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
    iflist = `ip link`.scan(/^\d+: (\w+):/).flatten
    lo = iflist.grep(/^lo/)
    lo = lo ? lo[0] : iflist[0]
    ifp = NWDIY::IFP.new(lo)
    expect(ifp).not_to be_nil
  end

  it '実在しないインターフェース名を与えたら、ソケットファイルを作る' do
    ifp = NWDIY::IFP.new('abcde')
    expect(ifp).not_to be_nil
  end

  it '{type: :pcap, name: <ifp>} を与えたら、そのインターフェースを pcap で開く' do
    iflist = `ip link`.scan(/^\d+: (\w+):/).flatten
    lo = iflist.grep(/^lo/)
    lo = lo ? lo[0] : iflist[0]
    ifp = NWDIY::IFP.new({type: :pcap, name: lo})
    expect(ifp).not_to be_nil
  end

  # it '{type: :tap, name: <file>} を与えたら、そのインターフェースを tap で作る' do
  #   ifp = NWDIY::IFP.new({type: :tap, name: 'tap'})
  #   expect(ifp).not_to be_nil
  # end

  it '{type: :sock, name: <file>} を与えたら、ソケットファイルを作ってくる' do
    ifp = NWDIY::IFP.new({type: :sock, name: 'lo'})
    expect(ifp).not_to be_nil
  end

  it 'pcap にパケットを送ったら、インターフェースから出てくる' do
    iflist = `ip link`.scan(/^\d+: (\w+):/).flatten
    lo = iflist.grep(/^lo/)
    lo = lo ? lo[0] : iflist[0]
    ifp = NWDIY::IFP.new(lo)
    expect(ifp.send('xxx')).to eq(3)
  end

end
