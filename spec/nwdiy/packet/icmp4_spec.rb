#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# IPv4 ICMP パケットのクラスです。
#
#【特異メソッド】
#
# new -> Nwdiy::Packet::ICMP4
#    (Nwdiy::Packet から継承)
#    IPv4 ICMP の空箱インスタンスを生成して返します。
#
# new(バイト列) -> Nwdiy::Packet::ICMP4
#    (Nwdiy::Packet から継承)
#    バイト列から IPv4 ICMP パケットインスタンスを生成して返します。
#
# new(Hash) -> Nwdiy::Packet::ICMP4
#    (Nwdiy::Packet から継承)
#    フィールド名ごとに値を指定して作成したインスタンスを返します。
#    指定できるフィールド名は以下のものです。
#
#      :type => 送信元ポート番号
#      :code => 宛先ポート番号
#      :data => データ
#
# to_pkt -> String
#    UDP パケットをバイト列に変換します
#
# inspect -> String
#    UDP パケットを可読形式で返します。
#
################################################################

require "spec_helper"

RSpec.describe Nwdiy::Packet::ICMP4 do
  it "can create ICMP from packet bytes" do
    type = "\x08"
    code = "\x00"
    sum  = "\xec\xe2"
    data = "\x09\x16\x00\x03\x00\x01\x02\x03"
    pkt = Nwdiy::Packet::ICMP4.new(type + code + sum + data)
    expect(pkt).to be_a Nwdiy::Packet::ICMP4
    expect(pkt.cksum).to be 0xece2
  end
end
