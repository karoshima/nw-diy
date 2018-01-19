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

  def initialize(seed = nil)
    @ipaddr = nil
    super(seed, { length: 8 } )
  end

  # パケット長は自動算出する
  def length
    self.nwdiy_set(:length,
                   8 + (self.data ? self.data.bytesize : 0))
  end

  def set_ipaddr(src, dst)
    @ipaddr = [src, dst]
  end
  def cksum
    sum, pkt = self.sum_and_packet
    return sum
  end

  # ボディ部
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
    self.length = 8 + seed.bytesize
  end

  alias :to_pkt_original :to_pkt
  def to_pkt
    sum, pkt = self.sum_and_packet
    return pkt
  end
  def sum_and_packet
    len = self.length # 参照するとき自動計算される
    unless @ipaddr
      return self.to_pkt_original
    end
    pseudo = @ipaddr.map{|p| p.to_pkt } + [[17, self.length].pack("n2")]
    udp = [self.src, self.dst, len].pack("n3")
    data = self.data ? self.data.to_pkt : ""
    self.cksum = sum = self.class.calc_cksum(*pseudo, udp, data)
    udp += [sum].pack("n")
    return sum, udp + data
  end
  def inspect
    sprintf("[UDP %u => %u%s]",
            self.src, self.dst,
            self.data ? " "+self.data.inspect : "")
  end
end
