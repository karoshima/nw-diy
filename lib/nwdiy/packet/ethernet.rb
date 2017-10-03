#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# Nwdiy::Packet::Ethernet はイーサネットフレームです
# 802.3 LLC や SNAP は将来検討です。
#
# 以下のメソッドで、フレーム種別を確認できます。
# - ethernet?
#
# そのほか Nwdiy::Packet の各種メソッドも使用可能です
################################################################

require "nwdiy/packet"

class Nwdiy::Packet::Ethernet < Nwdiy::Packet
  def_field Nwdiy::Packet::Mac,  :dst
  def_field Nwdiy::Packet::Mac,  :src
  def_field :uint16,             :type
  def parse_data(data)
    @data = data
  end
  attr_accessor :data

  def initialize(data = nil)
    if data == nil
      self.dst = Nwdiy::Packet::Mac.new("00:00:00:00:00:00")
      self.src = Nwdiy::Packet::Mac.new("00:00:00:00:00:00")
    else
      super(data)
    end
  end
end
