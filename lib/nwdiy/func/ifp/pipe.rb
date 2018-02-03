#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2017 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require "io/wait"

Thread.abort_on_exception = true

class Nwdiy::Func::Ifp::Pipe < Nwdiy::Func::Ifp

  def self.pair(a = nil, b = nil)
    pipes = [a, b].map {|name| self.new(name) }
    pipes[0].peer = pipes[1]
    pipes[1].peer = pipes[0]
    return pipes
  end
  
  attr_reader :queue
  attr_accessor :sent, :received

  # private

  attr_accessor :peer

  def initialize(name)
    super
    @queue = Thread::Queue.new
    @sent = @received = 0
    @peer = nil
  end
  def class_name
    "pipe"
  end

  public

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
    return pkt.bytesize
  end

  # on/off されることはない
  def power
    true
  end
  alias :on  :power
  alias :off :power
end
