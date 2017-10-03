#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# Nwdiy::Packet::ARP は ARP パケットです
# 仕様については spec/nwdiy/packet/arp_spec.rb を参照してください。
################################################################

require "nwdiy/packet"
require "nwdiy/packet/ethernet"

class Nwdiy::Packet
  autoload(:MacAddr,  "nwdiy/packet/macaddr")
  autoload(:IPv4Addr, "nwdiy/packet/ipv4addr")
end

class Nwdiy::Packet::ARP < Nwdiy::Packet
end

class Nwdiy::Packet::Ethernet
  @@ethertypes[Nwdiy::Packet::ARP] = 0x0806
  @@etherclass[0x0806] = Nwdiy::Packet::ARP
end

class Nwdiy::Packet::ARP
  def_field :uint16, :htype, :ptype
  def_field :uint8,  :hlen,  :plen
  def_field :uint8,  :op
  def_field Nwdiy::Packet::MacAddr,  :hsnd
  def_field Nwdiy::Packet::IPv4Addr, :psnd
  def_field Nwdiy::Packet::MacAddr,  :htgt
  def_field Nwdiy::Packet::IPv4Addr, :ptgt
end
