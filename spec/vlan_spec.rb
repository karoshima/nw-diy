#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2017 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require 'nwdiy/func/vlan'

describe NwDiy::VLAN, 'を作るとき' do
  before :all do
    @trunk = NwDiy::Interface.new 'trunk'
    @vlan0000 = NwDiy::Interface.new 'vlan0000'
    @vlan0001 = NwDiy::Interface.new 'vlan0001'
    @vlan0002 = NwDiy::Interface.new 'vlan0002'
    @vlan4093 = NwDiy::Interface.new 'vlan4093'
    @vlan4094 = NwDiy::Interface.new 'vlan4094'
    @vlan4095 = NwDiy::Interface.new 'vlan4095'

    @vlan = NwDiy::VLAN.new
    @thread = Thread.new { @vlan.run }

    @eth = NwDiy::Packet::Ethernet.new
    @eth.data = @ip = NwDiy::Packet::IPv4.new
  end

  it 'can hold vlan1-vlan4094' do
    @vlan.trunk = 'trunk'
    expect{@vlan[   0] = 'vlan0000'}.to raise_error(Errno::ENODEV)
    @vlan[1] = 'vlan0001'
    @vlan[2] = 'vlan0002'
    @vlan[4093] = 'vlan4093'
    @vlan[4094] = 'vlan4094'
    expect{@vlan[4095] = 'vlan4095'}.to raise_error(Errno::ENODEV)
  end

  it 'can flow un-tagged packet' do
    @vlan0001.send(@eth)
    sleep(0.01)
    expect(@trunk.recv_ready?).to be true
    expect(@vlan0000.recv_ready?).to be false
    expect(@vlan0001.recv_ready?).to be false
    expect(@vlan0002.recv_ready?).to be false
    expect(@vlan4093.recv_ready?).to be false
    expect(@vlan4094.recv_ready?).to be false
    expect(@vlan4095.recv_ready?).to be false
    if @trunk.recv_ready?
      pkt = @trunk.recv
      expect(pkt.data).to be_a_kind_of NwDiy::Packet::VLAN
      expect(pkt.data.vid).to eq 1
      expect(pkt.data.data).to be_a_kind_of NwDiy::Packet::IPv4
    end
  end

  it 'can flow tagged packet' do
    @eth.data = NwDiy::Packet::VLAN.new
    @eth.data.vid = 4094
    @eth.data.data = @ip
    @trunk.send(@eth)
    sleep(0.01)
    expect(@trunk.recv_ready?).to be false
    expect(@vlan0000.recv_ready?).to be false
    expect(@vlan0001.recv_ready?).to be false
    expect(@vlan0002.recv_ready?).to be false
    expect(@vlan4093.recv_ready?).to be false
    expect(@vlan4094.recv_ready?).to be true
    expect(@vlan4095.recv_ready?).to be false
    if @vlan4094.recv_ready?
      pkt = @vlan4094.recv
      expect(pkt.data).to be_a_kind_of NwDiy::Packet::IPv4
    end
  end
end
