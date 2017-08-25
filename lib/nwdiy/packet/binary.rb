#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# Nwdiy::Packet::Binary は謎のフレームです。
# とりあえず表示するときは 16 進ダンプします。
# Nwdiy::Packet の各種メソッドが使用可能です。
################################################################

require "nwdiy/packet"

class Nwdiy::Packet::Binary < String
  include Nwdiy::Packet

  def initialize(pkt = "")
    super(pkt.to_s)
  end

  ################
  # パケットの扱い
  def inspect
    "[Binary #{self.dump}]"
  end
  def ==(other)
    (other.kind_of?(self.class) || other.kind_of?(String)) &&
      super(other)
  end
end
