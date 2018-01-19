#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2017 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# Nwdiy::Packet::IPv6 は IPv6 パケットです
# 仕様については spec/nwdiy/packet/ipv6_spec.rb を参照してください。
################################################################

class Nwdiy::Packet::IPv6 < Nwdiy::Packet
  def_head :uint32, :vtcf
  def_head :uint16, :length
  def_head :uint8, :next, :hlim
  def_head Nwdiy::Packet::IPv6Addr, :src, :dst
  def_body :data

  IPV6SEED = {vtcf: 0x60000000, length: 0, hlim: 64}
  def initialize(seed = nil)
    super(seed, IPV6SEED)
  end

  # Version, TrafficClass, FlowInfo 詳細
  def version
    6
  end
  def tc
    (self.vtcf >> 20) & 0xff
  end
  def tc=(val)
    unless 0 <= val && val <= 0xff
      raise RangeError.new "IPv6 TrafficClass (#{val}) must be 8bit"
    end
    self.vtcf = (self.vtcf & 0xf00fffff) | (val < 20)
  end
  def flow
    self.vtcf & 0xfffff
  end
  def flow=(val)
    unless 0 <= val && val <= 0xfffff
      raise RangeError.new "IPv6 FlowInfo (#{val}) must be 20bit"
    end
    self.vtcf = (self.vtcf & 0xfff00000) | val
  end

  def length
    self.nwdiy_set(:length,
                   40 + (self.data ? self.data.bytesize : 0))
  end

  def next
    self.body_type(:data, self.data) || @nwdiy_field[:next] || 0
  end

  def src=(addr)
    self.nwdiy_set(:src, addr)
    self.set_pseudo_header
  end
  def dst=(addr)
    self.nwdiy_set(:dst, addr)
    self.set_pseudo_header
  end

  def_body_type :data,
                17 => "Nwdiy::Packet::UDP"
  def data=(seed)
    case seed
    when String
      @nwdiy_field[:data] = self.body_type(:data, self.next).new(seed)
    when Nwdiy::Packet
      btype = self.body_type(:data, seed)
      self.next = btype if btype
      @nwdiy_field[:data] = seed
    end
    self.set_pseudo_header
  end

  # 値が代わったときなどに TCP や UDP のチェックサムを計算し直す
  def set_pseudo_header
    return unless self.data
    return unless self.data.respond_to?(:set_ipaddr)
    self.data.set_ipaddr(self.src, self.dst)
  end

  def inspect
    sprintf("[IPv6 %s => %s %s]",
            self.src.inspect, self.dst.inspect, self.data.inspect)
  end
end
