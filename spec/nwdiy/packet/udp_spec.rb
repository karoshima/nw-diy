#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# UDP パケットのクラスです。
#
#【特異メソッド】
#
# new -> Nwdiy::Packet::UDP
#    (Nwdiy::Packet から継承)
#    UDP の空箱インスタンスを生成して返します。
#
# new(バイト列) -> Nwdiy::Packet::UDP
#    (Nwdiy::Packet から継承)
#    バイト列から UDP パケットインスタンスを生成して返します。
#
# new(Hash) -> Nwdiy::Packet::UDP
#    (Nwdiy::Packet から継承)
#    フィールド名ごとに値を指定して作成したインスタンスを返します。
#    指定できるフィールド名は以下のものです。
#
#      :src  => 送信元ポート番号
#      :dst  => 宛先ポート番号
#      :data => データ
#
#    以下のフィールドは存在しますが、自動算出するので指定はできません。
#
#      :length  (UDPパケット全長)
#      :cksum   UDP チェックサム
#
#【インスタンスメソッド】
#
# pseudo_header = String
#    UDP パケットのチェックサム計算に用いる pseudo header を
#    L3 ヘッダから貰います
#
# to_pkt -> String
#    UDP パケットをバイト列に変換します
#
# inspect -> String
#    UDP パケットを可読形式で返します。
#
################################################################

require "spec_helper"

RSpec.describe Nwdiy::Packet::UDP do
  it "can create udp from packet bytes" do
    data = "aaaa"
    src = "\x12\x34"
    dst = "\x00\x50"
    length = "\x00\x0c"
    cksum = "\x00\x00"
    pkt = Nwdiy::Packet::UDP.new(src + dst + length + cksum + data)
    expect(pkt).to be_a Nwdiy::Packet::UDP
  end
end
