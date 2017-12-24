#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2017 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# Nwdiy::Packet::UDP は UDP パケットです
# 仕様については spec/nwdiy/packet/udp_spec.rb を参照してください。
################################################################

class Nwdiy::Packet::UDP < Nwdiy::Packet
  def_head :uint16, :src, :dst, :length, :cksum
  def_body :data

  # チェックサム計算
  #    cksum 部を除いたヘッダ部のバイト列から
  #    チェックサム値を求める
  def cksum
    warn "Nwdiy::Packet::UDP の cksum 計算は、まだ疑似ヘッダを加えていません"
    self.cksum = 0
    pkt = self.to_pkt
    self.cksum = self.class.calc_cksum(pkt)
  end

  def_body_type :data, {}
  # def_body_type :data,
  #               7 => "Nwdiy::Packet::Echo",
  #               13 => "Nwdiy::Packet::Daytime",
  #               19 => "Nwdiy::Packet::Chargen",
  #               37 => "Nwdiy::Packet::Time",
  #               53 => "Nwdiy::Packet::Domain",
  #               123 => "Nwdiy::Packet::NTP"
  def data=(seed)
    unless seed.kind_of?(Nwdiy::Packet)
      cls = self.body_type(:data, self.src)
      cls = self.body_type(:data, self.dst) if cls == Nwdiy::Packet::Binary
      seed = cls.new(seed)
    end
    @nwdiy_field[:data] = seed
  end
end
