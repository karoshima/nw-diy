#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# Nwdiy::Packet::VLAN はイーサネットフレームの VLAN ヘッダ部分です
# 仕様については spec/nwdiy/packet/vlan_spec.rb を参照してください
################################################################

class Nwdiy::Packet::VLAN < Nwdiy::Packet
  def_head :uint16, :tci
  def_head :uint16, :type
  def_body :data
  def_body_type :data,
                0x0800 => "Nwdiy::Packet::IPv4",
                0x0806 => "Nwdiy::Packet::ARP"

  def initialize(data = nil, default={})
    if data.kind_of?(Hash)
      tci = data[:tci] || 0
      pcp = data.delete(:pcp) || 0
      cfi = data.delete(:cfi) || 0
      vid = data.delete(:vid) || 0
      data[:tci] = (tci & 0xffff) | ((pcp << 13) & 0xe000) | ((cfi << 12) & 0x1000) | (vid & 0x0fff)
    end
    super(data, default)
  end

  def pcp=(seed)
    self.tci = (self.tci & 0x1fff) | ((seed & 7) << 13)
  end
  def pcp
    (self.tci & 0xe000) >> 13
  end
  def cfi=(seed)
    self.tci = (self.tci & 0xefff) | ((seed & 1) << 12)
  end
  def cfi
    (self.tci & 0x1000) >> 12
  end
  def vid=(seed)
    self.tci = (self.tci & 0xf000) | ((seed & 0xfff) << 0)
  end
  def vid
    (self.tci & 0x0fff) >> 0
  end

  # same as ethernet.rb
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
    sprintf("[VLAN(%d) %04x %s]",
            vid, type, data.inspect)
  end
end
