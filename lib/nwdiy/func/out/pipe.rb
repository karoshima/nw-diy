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
  def initialize
    @queue = Thread::Queue.new
    @recv_dir = nil
    @send_dir = nil
  end
  def set_peer(peer)
    @peer = peer
  end
  def set_left
    @recv_dir = :to_right
    @send_dir = :to_left
  end
  def set_right
    @recv_dir = :to_left
    @send_dir = :to_right
  end

  attr_reader :queue

  def ready?
    !@queue.empty?
  end

  def recv
    pkt = @queue.shift
    pkt.direction = @recv_dir if @recv_dir
    pkt
  end

  def send(pkt)
    pkt.direction = @send_dir if @send_dir
    @peer.queue.push(pkt)
    pkt.bytesize
  end

  # どうせ on/off することはないので
  def power
    true
  end
  alias :on  :power
  alias :off :power
end
