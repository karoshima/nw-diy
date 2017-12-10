#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# IPv4 パケットのクラスです。
#
#【特異メソッド】
#
# new -> Nwdiy::Packet::IPv4
#    (Nwdiy::Packet から継承)
#    IPv4 の空箱インスタンスを生成して返します。
#
# new(バイト列) -> Nwdiy::Packet::IPv4
#    (Nwdiy::Packet から継承)
#    バイト列から IPv4 パケットインスタンスを生成して返します。
#
# new(Hash) -> Nwdiy::Packet::IPv4
#    (Nwdiy::Packet から継承)
#    フィールド名ごとに値を指定して作成したインスタンスを返します。
#    指定できるフィールド名は以下のものです。
#
#      :tos      => パケットの優先順位
#      :id       => 識別子
#      :frag     => フラグメント関連 (DF, MF, Offset)
#      :ttl      => TTL
#      :protocol => 次ヘッダの型
#      :src      => 送信元 IPv4 アドレス
#      :dst      => 送信先 IPv4 アドレス
#
#    以下のフィールドは存在しますが、自動算出するので指定はできません。
#
#      :version (IPバージョン)
#      :hlen    (IPヘッダ長)
#      :length  (IPパケット全長)
#      :cksum   IP チェックサム
#
#【インスタンスメソッド】
#
# option -> String [TBD]
#    オプションの中身をバイト列で返します。
#    [TBD] ホントは配列がいいんだろうなあ。
#    packet.rb 的には bytesize に応答する必要あり。
#
# option = String [TBD]
#    パケットのバイト列のうち、オプション以降を渡します。
#    self.hlen を参考にして、必要なぶんだけ option として取り込みます。
#    オプションの中身を精査したり追加削除するときのことは
#    まだうまく考慮できていません。
#
# to_s -> String
#    IPv4 パケットをバイト列に変換します
#
# inspect -> String
#    IPv6 パケットを可読形式で返します。
#
################################################################

require "spec_helper"

RSpec.describe Nwdiy::Packet::IPv4 do
  it "can create IPv4 from packet bytes" do
    vhl = "\x04\x05"
    tos = "\x00\x00"
    len = "0x00\x20"
    id  = "\x00\x02"
    frg = "\x00\x00"
    ttl = "\x80"
    pro = "\x02"
    sum = "\x00\x00"
    src = "\x7f\x00\x00\x01"
    dst = "\x7f\x00\x00\x02"
    data = "ABCDEFGHIJKL"
    pkt = Nwdiy::Packet::IPv4.new(vhl + tos + len + id + frg + ttl + pro + sum + src + dst + data)
    expect(pkt).to be_a Nwdiy::Packet::IPv4
  end
end
