#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require "nwdiy/vm"
require "nwdiy/iplink"

link = NwDiy::IpLink.new
ifp = (link['lo'] || link['lo0']).to_s

class NwDiy::Interface
  attr_reader :dev # 内部テスト用
end

describe NwDiy::VM, 'を作るとき' do
  it '引数が無くても作れる' do
    r = NwDiy::VM.new
    expect(r).not_to be_nil
    expect(r.iflist).to be_empty
  end

  if NwDiy::OS.linux?
    it '実在するインターフェース名を与えたら、そのインターフェースを pcap で開く' do
      r = NwDiy::VM.new(ifp)
      expect(r).not_to be_nil
      expect(r.iflist.size).to be(1)
      expect(r.iflist[0].class).to be(NwDiy::Interface)
      expect(r.iflist[0].dev.class).to be(NwDiy::Interface::Pcap).or be(NwDiy::Interface::Proxy)
    end
  end

  it '実在しないインターフェース名を与えたら、ソケットファイルを作る' do
    r = NwDiy::VM.new(ifp+'xxxxx')
    expect(r).not_to be_nil
    expect(r.iflist.size).to be(1)
    expect(r.iflist[0].class).to be(NwDiy::Interface)
    expect(r.iflist[0].dev.class).to be(NwDiy::Interface::Sock).or be(NwDiy::Interface::Proxy)
  end

  if NwDiy::OS.linux?
    it '{type: :pcap, name: <ifp>} を与えたら、そのインターフェースを pcap で開く' do
      r = NwDiy::VM.new({type: :pcap, name: ifp})
      expect(r).not_to be_nil
      expect(r.iflist.size).to be(1)
      expect(r.iflist[0].class).to be(NwDiy::Interface)
      expect(r.iflist[0].dev.class).to be(NwDiy::Interface::Pcap).or be(NwDiy::Interface::Proxy)
    end
  end

end
