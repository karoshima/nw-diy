#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require 'nwdiy/iplink'

describe 'ip link', 'のラッパー' do

  it 'should know the number of interfaces' do
    link = NwDiy::IpLink.new
    expect(link.length).to be > 0
  end

  it 'should check loopback interface' do
    link = NwDiy::IpLink.new
    expect(link['lo']).not_to be_nil
    expect(link['lo']).to be == 1
    expect(link['lo']).to be == 'lo'
  end

  it 'should exists 127.0.0.1' do
    link = NwDiy::IpLink.new
    expect(link['lo'].addr.grep('127.0.0.1')).not_to be_nil
  end

  it 'should be 00:00:00:00:00:00 of lo mac addr' do
    link = NwDiy::IpLink.new
    expect(link['lo'].mac).to be == "00:00:00:00:00:00"
  end
end
