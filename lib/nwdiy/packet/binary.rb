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

class Nwdiy::Packet::Binary < Nwdiy::Packet
  def_body :data
  def data=(seed)
    @nwdiy_field[:data] = seed.to_s
  end
  alias :to_pkt :data
  alias :inspect :data
end
