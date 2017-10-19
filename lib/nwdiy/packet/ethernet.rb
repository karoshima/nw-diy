#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# Nwdiy::Packet::Ethernet はイーサネットフレームです
# 仕様については spec/nwdiy/packet/ethernet_spec.rb を参照してください。
################################################################

require "nwdiy/packet"

class Nwdiy::Packet
  autoload(:Arp,      'nwdiy/packet/arp')
  autoload(:MacAddr,  'nwdiy/packet/macaddr')
end

class Nwdiy::Packet::Ethernet < Nwdiy::Packet
  def_field Nwdiy::Packet::MacAddr,  :dst
  def_field Nwdiy::Packet::MacAddr,  :src
  def_field :uint16,                 :type
  def parse_data(obj)
    self.data = obj
  end

  @@ethertypes = Hash.new
  @@etherclass = Hash.new

  # type は @data があればそのクラスを見て @type を見ない
  def type
    @@ethertypes[@data.class] ? @@ethertypes[@data.class] : @type
  end

  # データとして Nwdiy::Packet::XXX インスタンスを与えられたら
  # そのクラスに応じて @type も書き換える
  # そうじゃないデータを与えられたら
  # @type に応じて Nwdiy::Packet::XXX インスタンス化する
  attr_accessor :data
  def data=(obj)

    if @@ethertypes[obj.class]
      @type = @@ethertypes[obj.class]
      @data = obj
    elsif @@etherclass[self.type]
      @data = @@etherclass[self.type].new(obj)
    else
      @data = obj
    end
  end

  def initialize(data = nil)
    if data == nil
      self.dst = Nwdiy::Packet::MacAddr.new("00:00:00:00:00:00")
      self.src = Nwdiy::Packet::MacAddr.new("00:00:00:00:00:00")
    else
      super(data)
    end
  end

  def inspect
    sprintf("[Ethernet %s => %s %04x %s]", 
            src.inspect, dst.inspect, 
            type, 
            data.inspect)
  end
end
