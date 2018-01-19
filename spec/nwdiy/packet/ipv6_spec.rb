#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# IPv6 パケットのクラスです。
#
#【特異メソッド】
#
# new -> Nwdiy::Packet::IPv6
#    (Nwdiy::Packet から継承)
#    IPv6 の空箱インスタンスを生成して返します。
#
# new(バイト列) -> Nwdiy::Packet::IPv6
#    (Nwdiy::Packet から継承)
#    バイト列から IPv6 パケットインスタンスを生成して返します。
#
# new(Hash) -> Nwdiy::Packet::IPv6
#    (Nwdiy::Packet から継承)
#    フィールド名ごとに値を指定して作成したインスタンスを返します。
#    指定できるフィールド名は以下のものです。
#
#      :tc       => パケットの優先順位
#      :flow     => フローラベル
#      :next     => 次ヘッダの型
#      :hlim     => ホップリミット
#      :src      => 送信元 IPv4 アドレス
#      :dst      => 送信先 IPv4 アドレス
#
#    以下のフィールドは存在しますが、自動算出するので指定はできません。
#
#      :version (IPバージョン)
#      :length  (IPパケット全長)
#
#【インスタンスメソッド】
#
# to_pkt -> String
#    IPv6 パケットをバイト列に変換します
#
# inspect -> String
#    IPv6 パケットを可読形式で返します。
#
################################################################

require "spec_helper"

RSpec.describe Nwdiy::Packet::IPv6 do
  it "can create IPv6 from packet bytes" do
    pkt = Nwdiy::Packet::IPv6.new("\x06\x00\x00\x00\x00\x30\x02\x40" +
                                  [0xfe80, 0, 0, 0, 0, 0, 0, 1].pack("n8") +
                                  [0xfe80, 0, 0, 0, 0, 0, 0, 2].pack("n8") +
                                  "ABCDEFGH")
    expect(pkt).to be_a Nwdiy::Packet::IPv6
  end

  it 'UDPデータを突っ込んだら next が UDP になること' do
    data = Nwdiy::Packet::UDP.new
    pkt = Nwdiy::Packet::IPv6.new
    pkt.data = data
    expect(pkt.next).to be 17
    pkt = Nwdiy::Packet::IPv6.new(:data => data)
    expect(pkt.next).to be 17
  end

  it "proto を 17 にしたら UDP になること" do
    xxx = "ABCDEFGH"
    pkt = Nwdiy::Packet::IPv6.new(next: 17)
    pkt.data = xxx
    expect(pkt.data).to be_a Nwdiy::Packet::UDP
  end

  # it "TCP/UDP であれば pseudo header を与えてあげる" do
  #   pkt = Nwdiy::Packet::IPv6.new(src: "fe80::1", dst: "fe80::2")
  #   xxx = Nwdiy::Packet::UDP.new(data: "xxxxxxxxxxxxxxxx")
  #   pkt.data = xxx
  #   expect(pkt.data.cksum).to be 0xfd55
  # end

  # it "実データをキャプチャしたものから" do
  #   pkt = Nwdiy::Packet::IPv6.new("\x60\x0c\xce\x1b\x00\x28\x11\x40" +
  #                                 "\x20\x01\xdb\xdb\x00\x00\x00\x00" +
  #                                 "\x00\x00\x00\x00\x00\x00\x00\x02" +
  #                                 "\x20\x01\xdb\xdb\x00\x00\x00\x00" +
  #                                 "\x00\x00\x00\x00\x00\x00\x00\x01" +
  #                                 "\xe6\xa4\x00\x35\x00\x28\xf7\xf5" +
  #                                 "\xe7\xeb\x01\x00\x00\x01\x00\x00" +
  #                                 "\x00\x00\x00\x00\x03\x6e\x74\x70" +
  #                                 "\x06\x75\x62\x75\x6e\x74\x75\x03" +
  #                                 "\x63\x6f\x6d\x00\x00\x1c\x00\x01")
  #   expect(pkt.data).to be_a Nwdiy::Packet::UDP
  #   expect(pkt.data.cksum).to eq 0xf7f5
  # end
end
