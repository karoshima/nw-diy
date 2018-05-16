#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Ethernet フレームの VLAN ヘッダ部分のクラスです。
#
#【特異メソッド】
#
# new -> Nwdiy::Packet::VLAN
#    (Nwdiy::Packet から継承)
#    Ethernet フレームの VLAN 部分の空箱インスタンスを生成して返します。
#
# new(バイト列) -> Nwdiy::Packet::VLAN
#    (Nwdiy::Packet から継承)
#    バイト列から Ethernet フレームの VLAN 部分のインスタンスを生成して返します。
#
# new(Hash) -> Nwdiy::Packet::VLAN
#    (Nwdiy::Packet から継承)
#    ハッシュ値から Ethernet フレームインスタンスを生成して返します。
#    ハッシュのキーには以下のキーが使用できます。
#    :tci    PCP, CFI, VID の合成値
#    :pcp    優先度 (3bit)
#    :cfi    フォーマット識別子 (イーサネットでは0
#    :vid    VLAN ID
#    :type   データ種別 (バイト列あるいは数値)
#    :data   データ部 (バイト列あるいは適切なインスタンス)
#
#【インスタンスメソッド】
#
################################################################


require "spec_helper"

RSpec.describe Nwdiy::Packet::VLAN do
  it "creates empty VLAN packet" do
    pkt = Nwdiy::Packet::VLAN.new
    expect(pkt.tci).to be 0
  end

  it "creates an VLAN packet with bytes" do
    pkt = Nwdiy::Packet::VLAN.new("\x00\x01\x08\x01Hello World")
    expect(pkt.vid).to be 1
    expect(pkt.type).to be 0x0801
    expect(pkt.data.to_pkt).to eq "Hello World"
  end

  it "creates an VLAN packet with hash" do
    pcp = 5
    id = 2
    type = 0x0801
    data = "Hello World"
    pkt = Nwdiy::Packet::VLAN.new(pcp: pcp, vid: id, 
                                  type: type, data: data)
    expect(pkt.pcp).to eq pcp
    expect(pkt.vid).to eq id
    expect(pkt.type).to eq type
    expect(pkt.data.to_pkt).to eq data
  end
end
