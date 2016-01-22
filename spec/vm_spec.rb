#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require "vm"

describe NWDIY::VM, 'を作るとき' do
  it '引数が無くても作れる' do
    r = NWDIY::VM.new
    expect(r).not_to be_nil
    expect(r.iflist).to be_empty
  end

  it '文字列引数を与えたら、ソケットファイルを作ってくる' do
    r = NWDIY::VM.new('lo')
    expect(r).not_to be_nil
    expect(r.iflist.size).to be(1)
    expect(r.iflist[0]).to be_kind_of(UNIXSocket)
  end

  it '{type: :pcap, name: <ifp>} を与えたら、ソケットファイルを作ってくる' do
    r = NWDIY::VM.new({type: :pcap, name: 'lo'})
    expect(r).not_to be_nil
    expect(r.iflist.size).to be(1)
    expect(r.iflist[0]).to be_kind_of(IO)
  end

  it '{type: :tap, name: <file>} を与えたら、ソケットファイルを作ってくる' do
    r = NWDIY::VM.new({type: :tap, name: 'lo'})
    expect(r).not_to be_nil
    expect(r.iflist.size).to be(1)
    expect(r.iflist[0]).to be_kind_of(IO)
  end

  it '{type: :file, name: <file>} を与えたら、ソケットファイルを作ってくる' do
    r = NWDIY::VM.new({type: :file, name: 'lo'})
    expect(r).not_to be_nil
    expect(r.iflist.size).to be(1)
    expect(r.iflist[0]).to be_kind_of(UNIXSocket)
  end
end
