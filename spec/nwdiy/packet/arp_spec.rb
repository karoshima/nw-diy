#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# ARP パケットのクラスです。
#
#【特異メソッド】
#
# new -> Nwdiy::Packet::ARP
#    (Nwdiy::Packet から継承)
#    ARP パケットの空箱インスタンスを生成して返します
#
# new(バイト列) -> Nwdiy::Packet::ARP
#    (Nwdiy::Packet から継承)
#    バイト列から ARP パケットインスタンスを生成して返します。
#
# new(Hash) -> Nwdiy::Packet::ARP
#    (Nwdiy::Packet から継承)
#    フィールド名ごとに値を指定して作成したインスタンスを返します。
#    指定できるフィールド名は以下のものです。
#
#      :htype => ハードウェア種別 (イーサネットは 1)
#      :ptype => プロトコル種別 (IPv4 では 0x0800)
#      :hlen  => ハードウェアアドレス長 (イーサネットでは 6)
#      :plen  => プロトコルアドレス長 (IPv4 では 4)
#      :op    => オペレーション (1: リクエスト, 2:リプライ)
#      :hsnd  => 送信元ハードウェアアドレス (MAC アドレス)
#      :psnd  => 送信元プロトコルアドレス (IPv4 アドレス)
#      :htgt  => ターゲットハードウェアアドレス (MAC アドレス)
#      :ptgt  => ターゲットプロトコルアドレス (IPv4 アドレス)
#
#【インスタンスメソッド】
#
# to_s -> String
#    (Nwdiy::Pacet から継承)
#    Mac アドレスをバイト列に変換します
#
# inspect -> String
#    (Nwdiy::Pacet から継承)
#    Mac アドレスを可読形式で返します
#
################################################################

require "spec_helper"

RSpec.describe Nwdiy::Packet::ARP do
  it "can create ARP from packet bytes" do
    hdst = "\x00\x00\x0e\x00\x00\x01"
    hsrc = "\x00\x00\x0e\x00\x00\x02"
    htype = "\x08\x06"
    arp = "\x00\x01\x08\x00\x06\x04\x00\x01"
    pdst = "\x0a\x00\x00\x01"
    psrc = "\x0a\x00\x00\x02"
    eth = Nwdiy::Packet::Ethernet.new(hdst + hsrc + htype + arp + hsrc + psrc + hdst + pdst)
    expect(eth).to be_a(Nwdiy::Packet::Ethernet)
    expect(eth.data).to be_a(Nwdiy::Packet::ARP)
    expect(eth.data.htype).to eq(1)
    expect(eth.data.ptype).to eq(0x0800)
    expect(eth.data.hlen).to eq(6)
    expect(eth.data.plen).to eq(4)
    expect(eth.data.op).to eq(1)
    expect(eth.data.hsnd.inspect).to eq("00:00:0e:00:00:02")
    expect(eth.data.psnd.inspect).to eq("10.0.0.2")
    expect(eth.data.htgt.inspect).to eq("00:00:0e:00:00:01")
    expect(eth.data.ptgt.inspect).to eq("10.0.0.1")
    expect(eth.inspect).to eq "[Ethernet 00:00:0e:00:00:02 => 00:00:0e:00:00:01 0806 [ARP Request 00:00:0e:00:00:02/10.0.0.2 => 00:00:0e:00:00:01/10.0.0.1]]"
  end
end
