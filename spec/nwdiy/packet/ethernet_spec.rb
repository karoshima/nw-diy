#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Ethernet フレームのクラスです。
#
#【特異メソッド】
#
# new -> Nwdiy::Packet::Ethernet
#    (Nwdiy::Packet から継承)
#    Ethernet フレームの空箱インスタンスを生成して返します。
#
# new(バイト列) -> Nwdiy::Packet::Ethernet
#    (Nwdiy::Packet から継承)
#    バイト列から Ethernet フレームインスタンスを生成して返します。
#
# new(Hash) -> Nwdiy::Packet::Ethernet
#    (Nwdiy::Packet から継承)
#    ハッシュ値から Ethernet フレームインスタンスを生成して返します。
#    ハッシュのキーには以下のキーが使用できます。
#    :dst    宛先 Mac (バイト列あるいは Nwdiy::Packet::Mac インスタンス)
#    :src    送信元 Mac (同上)
#    :type   データ種別 (バイト列あるいは数値)
#    :data   データ部 (バイト列あるいは適切なインスタンス)
#
#【インスタンスメソッド】
#
# dst -> Nwdiy::Packet::Mac
# src -> Nwdiy::Packet::Mac
#    (Nwdiy::Packet から継承)
#    Ethernet フレームの宛先/送信元アドレスを返します。
#
# dst=(mac)
# src=(mac)
#    (Nwdiy::Packet から継承)
#    Ethernet フレームの宛先/送信元アドレスを設定します。
#    mac は 6byte のバイト列, 可読形式の Mac アドレス,
#    あるいは Nwdiy::Packet::Mac インスタンスのいすれかです。
#
# to_s -> String
#    (Nwdiy::Packet から継承)
#    Ethernet フレームをバイト列に変換します。
#
# inspect -> String
#    (Nwdiy::Packet から継承)
#    Ethernet フレームを可読形式で返します。
#
################################################################

require "spec_helper"

RSpec.describe Nwdiy::Packet::Ethernet do
  it "creates empty ethernet packet" do
    pkt = Nwdiy::Packet::Ethernet.new
    expect(pkt.dst).to eq("00:00:00:00:00:00")
  end

  it "creates an ethernet packet with bytes" do
    dst = "\x00\x00\x0e\x00\x00\x01"
    src = "\x00\x00\x0e\x00\x00\x02"
    type = "\x08\x01"
    data = "Hello World"
    eth = Nwdiy::Packet::Ethernet.new(dst + src + type + data)
    expect(eth.dst).to eq(dst)
    expect(eth.src).to eq(src)
    expect(eth.type).to eq(0x0801)
    expect(eth.data).to eq(data)
  end

  it "creates an ethernet packet with hash" do
    dst = "\x00\x00\x0e\x00\x00\x01"
    src = "\x00\x00\x0e\x00\x00\x02"
    type = "\x08\x02"
    data = "Hello World"
    eth = Nwdiy::Packet::Ethernet.new(dst: dst, src: src, 
                                      type: type, data: data)
    expect(eth.dst).to eq(dst)
    expect(eth.src).to eq(src)
    expect(eth.type).to eq(0x0802)
    expect(eth.data).to eq(data)
  end
end
