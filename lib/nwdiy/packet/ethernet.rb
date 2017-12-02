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

class Nwdiy::Packet
  autoload(:Arp,      'nwdiy/packet/arp')
  autoload(:MacAddr,  'nwdiy/packet/macaddr')
end

class Nwdiy::Packet::Ethernet < Nwdiy::Packet
  def_head Nwdiy::Packet::MacAddr,  :dst
  def_head Nwdiy::Packet::MacAddr,  :src
  def_head :uint16,                 :type
  def_body :data
  def_body_type :data,
                0x0806 => "Nwdiy::Packet::ARP"
  def data=(seed)
    case seed
    when String
      @nwdiy_field[:data] = self.body_type(:data, self.type).new(seed)
    when Nwdiy::Packet
      self.type = self.body_type(:data, seed)
      @nwdiy_field[:data] = seed
    end
  end

  def inspect
    sprintf("[Ethernet %s => %s %04x %s]", 
            src.inspect, dst.inspect, 
            type, 
            data.inspect)
  end
end
