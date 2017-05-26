#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2017 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require 'nwdiy/func/l2sw'

describe NwDiy::L2Switch, 'を作るとき' do
  before :all do
    @fxp0 = NwDiy::Interface.new('fxp0')
    @fxp1 = NwDiy::Interface.new('fxp1')
    @fxp2 = NwDiy::Interface.new('fxp2')

    @sw = NwDiy::L2Switch.new('fxp0', 'fxp1', 'fxp2')
    @thread = Thread.new { @sw.run }

    @pkt = NwDiy::Packet::Ethernet.new
    @pkt.data = "Hello"
  end

  it 'floods a broadcast packet' do
    @pkt.src = "00:00:00:00:ff:00"
    @pkt.dst = "ff:ff:ff:ff:ff:ff"
    @fxp0.send(@pkt)
    sleep(0.01)
    expect(@fxp1.recv_ready?).to be true
    if @fxp1.recv_ready?
      expect(@fxp1.recv.data.to_pkt).to eq "Hello"
    end
    expect(@fxp2.recv_ready?).to be true
    if @fxp2.recv_ready?
      expect(@fxp2.recv.data.to_pkt).to eq "Hello"
    end
  end

  it 'floods a packet with unknown destination' do
    @pkt.src = "00:00:00:00:ff:01"
    @pkt.dst = "00:00:00:00:ff:02"
    @fxp1.send(@pkt)
    sleep(0.01)
    expect(@fxp0.recv_ready?).to be true
    if @fxp0.recv_ready?
      expect(@fxp0.recv.data.to_pkt).to eq "Hello"
    end
    expect(@fxp2.recv_ready?).to be true
    if @fxp2.recv_ready?
      expect(@fxp2.recv.data.to_pkt).to eq "Hello"
    end
  end

  it 'forward a packet with remembered destination' do
    @pkt.dst = "00:00:00:00:ff:02"
    @pkt.src = "00:00:00:00:ff:01"
    @fxp2.send(@pkt)
    sleep(0.01)
    expect(@fxp0.recv_ready?).to be false
    expect(@fxp1.recv_ready?).to be true
    if @fxp1.recv_ready?
      expect(@fxp1.recv.data.to_pkt).to eq "Hello"
    end
  end
end
