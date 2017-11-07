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
  def_head :uint16, :htype, :ptype
  def_head :uint8,  :hlen,  :plen
  def_head :uint16, :op
  def_head Nwdiy::Packet::MacAddr,  :hsnd
  def_head Nwdiy::Packet::IPv4Addr, :psnd
  def_head Nwdiy::Packet::MacAddr,  :htgt
  def_head Nwdiy::Packet::IPv4Addr, :ptgt

  OPNAME = [nil, "Request", "Response"]

  def inspect
    sprintf("[ARP %s %s/%s => %s/%s]",
            OPNAME[op] || "Unknown#{op}",
            hsnd.inspect, psnd.inspect,
            htgt.inspect, ptgt.inspect)
  end
end
