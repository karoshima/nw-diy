#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2017 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require_relative '../lib/nwdiy/interface'
require_relative '../util/pinger'
require_relative '../util/repeater'

Thread.abort_on_exception = true

class Rendezvous
  @@id = 0;
  def initialize(num)
    @@id   = @@id + 1
    @id    = @@id
    @num   = num
    @mutex = Mutex.new
    @cond  = ConditionVariable.new
  end
  def wait
    @mutex.synchronize do
      @num = @num - 1
      @cond.broadcast
    end
    @mutex.synchronize do
      while (@num > 0)
        @cond.wait(@mutex, 0.1)
      end
    end
  end
end

describe NwDiy::Interface, 'passes data' do
  # PC(A) からデータを送信する
  # サーバ(B) でデータを受信する
  # 監視さん(C) で監視する
  it 'runs test 1 scenario' do

    rp1 = Rendezvous.new(2)
    rp2 = Rendezvous.new(2)
    data = 'Hello'

    a = Thread.new do
      Thread.current.name = 'PC(A)'
      eth0 = NwDiy::Interface.new "eth0"
      expect(eth0.class).to eq NwDiy::Interface
      rp1.wait
      expect(eth0.send data).to eq 5
      rp2.wait
    end
    b = Thread.new do
      Thread.current.name = 'SERVER(B)'
      eth0 = NwDiy::Interface.new "eth0"
      expect(eth0.class).to eq NwDiy::Interface
      rp1.wait
      rp2.wait
      expect(eth0.recv).to eq data
    end
    a.join
    b.join
  end
end

describe NwDiy::Pinger, 'send/recv ICMP' do
  # PC(A) からハブ(B)を介して鯖(C)に ping を打ち
  # 応答を確認する
  it 'runs test 2 scenario' do

    rp1 = Rendezvous.new(3)

    a = Thread.new do
      pinger = NwDiy::Pinger.new("eth1", "192.168.1.1")
      rp1.wait
      system "sleep 1"
      ping = pinger.ping("192.168.1.2")
      expect(ping.class).to eq NwDiy::Packet::Ethernet
    end
    b = Thread.new do
      repeater = NwDiy::Repeater.new("eth1", "eth2")
      rp1.wait
      repeater.run
    end
    c = Thread.new do
      server = NwDiy::Pinger.new("eth2", "192.168.1.2")
      rp1.wait
      pong = server.pong
    end
    a.join
    b.kill
    c.kill
  end
end
