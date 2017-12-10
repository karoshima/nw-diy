#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2017 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# Nwdiy::Packet::IPv4 は IPv4 パケットです
# 仕様については spec/nwdiy/packet/arp_spec.rb を参照してください。
################################################################

class Nwdiy::Packet::IPv4 < Nwdiy::Packet
  def_head :uint8,  :vhl, :tos
  def_head :uint16, :length, :id, :frag
  def_head :uint8,  :ttl, :proto
  def_head :uint16, :cksum
  def_head Nwdiy::Packet::IPv4Addr, :src, :dst
  def_body          :option, :data

  # vhl 詳細
  def vhl=(value)
    @nwdiy_field[:vhl] = 0x40 | (value & 0x0f)
  end
  def version
    4
  end
  def hlen
    self.vhl & 0x0f
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
    self.frag = (self.frag & 0x6000) | (off & 0x1fff)
  end

  # チェックサム計算
  #    cksum 部を除いたヘッダ部のバイト列から
  #    チェックサム値を求める
  HEAD = [:vhl, :tos, :length, :id, :frag, :ttl, :proto, :src, :dst, :option]
  def cksum
    seed = HEAD.inject("") do |str, head|
      if @nwdiy_field[head].respond_to? :to_pkt
        str += @@nwdiy_field[head].to_pkt
      else
        str += @@nwdiy_field[head].to_s
      end
    end
    self.class.calc_cksum(str)
  end

  # オプション設定
  #    パケットのバイト列から取り込むところだけ実装してある
  #    内容に関する処理を実装する必要がある (TBD)
  def option=(byte)
    @nwdiy_field[:option] = byte[0..(self.hlen-20)]
  end

  def_type_body :data,
                1,  "Nwdiy::Packet::ICMP",
                6,  "Nwdiy::Packet::TCP",
                14, "Nwdiy::Packet::UDP"
  def data=(seed)
    case seed
    when String
      @nwdiy_field[:data] = self.body_type(:data, self.proto).new(seed)
    when Nwdiy::Packet
      self.proto = self.body_type(:data2, seed)
      @nwdiy_field[:data] = seed
    end
  end

  def inspect
    sprintf("[IPv4 %s => %s %s]",
            self.src, self.dst, self.data)
  end
end
