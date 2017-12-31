#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

class Nwdiy::Func::Out::Pipe < Nwdiy::Func::Out
  def self.pair
    a = self.new
    b = self.new
    a.set_peer(b)
    b.set_peer(a)
    return a, b
  end

  attr_accessor :sent, :received

  def initialize
    @queue = Thread::Queue.new
    @sent = @received = 0
  end
  def set_peer(peer)
    @peer = peer
  end

  attr_reader :queue

  def ready?
    !@queue.empty?
  end

  def recv
    pkt = @queue.shift
    @received += 1
    return pkt
  end

  def send(pkt)
    @peer.queue.push(pkt)
    @sent += 1
    pkt.bytesize
  end

  # どうせ on/off することはないので
  def power
    true
  end
  alias :on  :power
  alias :off :power
end
