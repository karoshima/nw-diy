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
  end

  it 'floods a broadcast packet' do
    @pkt.src = "00:00:00:00:ff:00"
    @pkt.dst = "ff:ff:ff:ff:ff:ff"
    @pkt.data = "Hello-1"
    @fxp0.send(@pkt)
    expect(@fxp1.recv_ready?(1)).to be true
    if @fxp1.recv_ready?
      expect(@fxp1.recv.data.to_pkt).to eq "Hello-1"
    end
    expect(@fxp2.recv_ready?(1)).to be true
    if @fxp2.recv_ready?
      expect(@fxp2.recv.data.to_pkt).to eq "Hello-1"
    end
  end

  it 'floods a packet with unknown destination, and the reply with known destination' do
    @pkt.src = "00:00:00:00:ff:01"
    @pkt.dst = "00:00:00:00:ff:02"
    @pkt.data = "Hello-2"
    @fxp1.send(@pkt)
    expect(@fxp0.recv_ready?(1)).to be true
    if @fxp0.recv_ready?
      expect(@fxp0.recv.data.to_pkt).to eq "Hello-2"
    end
    expect(@fxp2.recv_ready?(1)).to be true
    if @fxp2.recv_ready?
      expect(@fxp2.recv.data.to_pkt).to eq "Hello-2"
    end

    @pkt.src = "00:00:00:00:ff:02"
    @pkt.dst = "00:00:00:00:ff:01"
    @pkt.data = "Hello-3"
    @fxp2.send(@pkt)
    expect(@fxp0.recv_ready?(1)).to be false
    expect(@fxp1.recv_ready?).to be true
    if @fxp1.recv_ready?
      expect(@fxp1.recv.data.to_pkt).to eq "Hello-3"
    end
  end
end
