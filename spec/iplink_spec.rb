#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require 'iplink'

describe 'ip link', 'のラッパー' do

  it 'should インターフェース数が分かるべし' do
    link = NWDIY::IPLINK.new
    expect(link.length).to be > 0
  end

  it 'should check loopback interface' do
    link = NWDIY::IPLINK.new
    expect(link['lo']).not_to be_nil
  end

  it 'should exists 127.0.0.1' do
    link = NWDIY::IPLINK.new
    expect(link['lo'].addr.grep('127.0.0.1')).not_to be_nil
  end
end
