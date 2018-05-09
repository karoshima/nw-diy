#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2018 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# with Apache-2 license.  check /LICENSE please.
################################################################
# Ethernet interface

require "spec_helper"

RSpec.describe Nwdiy::Func::PktQueue do
  it '#initialize' do
    que = Nwdiy::Func::PktQueue.new
    # check the queue settings
    expect(que.max).to eq Nwdiy::Func::PktQueue::MAXQLEN
    expect(que.max = 4).to eq 4
    expect(que.length).to eq 0
    # push pkts (not overflow yet)
    (0..2).each {|x| que << x }
    sleep 0.1
    expect(que.length).to eq 3
    expect(que.pop).to be 0
    # push pkts (overflow!)
    (3..20).each {|x| que << x }
    sleep 0.1
    expect(que.length).to eq que.max
    expect(que.pop).to be 17
  end
end
