#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2017 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# Nwdiy::Packet::IPv4 は IPv4 パケットです
# 仕様については spec/nwdiy/packet/ipv4_spec.rb を参照してください。
################################################################

class Nwdiy::Packet::IPv4 < Nwdiy::Packet
  def_head :uint8,  :vhl, :tos
  def_head :uint16, :length, :id, :frag
  def_head :uint8,  :ttl, :proto
  def_head :uint16, :cksum
  def_head Nwdiy::Packet::IPv4Addr, :src, :dst
  def_body          :option, :data

  def initialize(seed = {vhl: 0x45, length: 20, ttl: 64})
    case seed
    when Hash
      seed[:vhl]    = 0x45 unless seed.has_key? :vhl
      seed[:length] =   20 unless seed.has_key? :length
      seed[:ttl]    =   64 unless seed.has_key? :ttl
    end
    super(seed)
  end

  # vhl 詳細
  def vhl=(value)
    @nwdiy_field[:vhl] = 0x40 | (value & 0x0f)
  end
  def version
    4
  end
  def hlen
    (self.vhl & 0x0f) * 4
  end
  # def hlen=()
  #   option への代入を詳細するとき検討する

  # フラグメント詳細
  def df
    (self.frag & 0x4000) != 0
  end
  def df=(flag)
    if flag
      self.frag |=  0x4000
    else
      self.frag &= ~0x400
    end
  end
  def mf
    (self.frag & 0x2000) != 0
  end
  def mf=(flag)
    if frag
      self.frag |=  0x2000
    else
      self.frag &= ~0x2000
    end
  end
  def offset
    self.frag &= 0x1fff
  end
  def offset=(off)
    unless 0 <= off && off <= 0x1fff
      raise RangeError.new "IPv4 offset (#{off}) is out of range"
    end
    self.frag = (self.frag & 0x6000) | (off & 0x1fff)
  end

  # チェックサム計算
  #    cksum 部を除いたヘッダ部のバイト列から
  #    チェックサム値を求める
  def cksum
    self.cksum = 0
    header = self.to_pkt(body: false)
    self.cksum = self.class.calc_cksum(header)
  end

  # オプション設定
  #    パケットのバイト列から取り込むところだけ実装してある
  #    内容に関する処理を実装する必要がある (TBD)
  def option=(byte)
    if self.hlen <= 20
      @nwdiy_field[:option] = ""
    else
      @nwdiy_field[:option] = byte[0..(self.hlen-20)]
    end
  end

#  def_body_type :data,
#                1  => "Nwdiy::Packet::ICMP",
#                6  => "Nwdiy::Packet::TCP",
#                14 => "Nwdiy::Packet::UDP"
  def_body_type :data,
                14 => "Nwdiy::Packet::UDP"
  def data=(seed)
    case seed
    when String
      @nwdiy_field[:data] = self.body_type(:data, self.proto).new(seed)
    when Nwdiy::Packet
      btype = self.body_type(:data, seed)
      self.proto = btype if btype
      @nwdiy_field[:data] = seed
    end
    self.length = self.hlen + @nwdiy_field[:data].to_pkt.bytesize
  end

  def inspect
    sprintf("[IPv4 %s => %s %s]",
            self.src.inspect, self.dst.inspect, self.data)
  end
end
