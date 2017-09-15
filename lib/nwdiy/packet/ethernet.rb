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
  def_field Nwdiy::Packet::MAC,  :dst
  def_field Nwdiy::Packet::MAC,  :src
  def_array Nwdiy::Packet::VLAN, :vlan
  def_field :uint16,             :type
  def_field :datatype            :data

  def datatype(data)
    Nwdiy::Packet::Binary
  end
end
