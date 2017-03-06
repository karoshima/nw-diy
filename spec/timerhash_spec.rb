#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2017 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require 'nwdiy/timerhash'

describe NwDiy::TimerHash, 'を作るとき' do
  before do
    @hash = NwDiy::TimerHash.new
  end

  it 'has a readable attribute' do
    expect(@hash.update).to be true
    expect(@hash.oldvalue).to be false
    expect(@hash.age).to eq Float::INFINITY
    expect(@hash.autodelete).to be true
  end

  it 'can hold and check a data' do
    @hash[:a] = 1
    expect(@hash[:a]).to be 1
  end

  it 'can hold and check aged data' do
    @hash[:a, -1] = 1
    @hash[:b, 0] = 2
    @hash[:c, 1] = 3
    expect(@hash[:a]).to be nil
    expect(@hash[:b]).to be 2
    expect(@hash[:c]).to be 3
  end

  it 'can delete a data' do
    @hash[:a] = 1
    @hash[:b, -1] = 2
    @hash[:c,  0] = 3
    @hash[:d,  1] = 4
    expect(@hash.delete(:a)).to be 1
    expect(@hash.delete(:b)).to be nil
    expect(@hash.delete(:c)).to be 3
    expect(@hash.delete(:d)).to be 4
  end

  it 'can set & get age' do
    @hash[:a] = 1
    expect(@hash.get_age(:a)).to eq Float::INFINITY
    @hash.set_age(:a, 1)
    expect(@hash.get_age(:a)).to be 1
    @hash.set_age(:a, -1)
    expect(@hash.get_age(:a)).to be nil
  end

  it 'can exec "each"' do
    @hash[:a] = 1
    @hash[:c,  0] = 3
    @hash[:d,  1] = 4
    @hash.each do |key,value|
      expect(key).to be_a(Symbol)
      expect(value).to be_a(Integer)
    end
  end
end
