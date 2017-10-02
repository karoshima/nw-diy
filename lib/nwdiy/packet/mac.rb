#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require "nwdiy/packet"

class Nwdiy::Packet::Mac < Nwdiy::Packet
  def_field :byte6, :addr

  def to_s
    self.addr
  end
  def bytesize
    6
  end
  def self.bytesize
    6
  end
  def inspect
    self.addr.unpack("C6").map{|c| "%02x"%c }.join(":")
  end
end
