#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2017 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# Nwdiy::Packet::ICMP4 は IPv4 ICMP パケットです
# 仕様については spec/nwdiy/packet/udp_spec.rb を参照してください。
################################################################

class Nwdiy::Packet::ICMP4 < Nwdiy::Packet
  def_head :uint8,  :type, :code
  def_head :uint16, :cksum
  def_body :data

  # チェックサム計算
  def cksum
    self.cksum = 0
    self.cksum = self.class.calc_cksum(self.to_pkt)
  end

  # ボディ部
  def_body_type :data, {}
  def data=(seed)
    unless seed.kind_of?(Nwdiy::Packet)
      seed = self.body_type(:data, self.type).new(seed)
    end
    @nwdiy_field[:data] = seed
  end
end
