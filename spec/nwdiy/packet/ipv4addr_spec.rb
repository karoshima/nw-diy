#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# IPv4 アドレスのクラスです。
#
#【特異メソッド】
# new(4byteのバイト列) -> Nwdiy::Packet::IPv4
#    (Nwdiy::Packet から継承)
#    バイト列から IPv4 アドレスインスタンスを生成して返します。
#
# new("xxx.xxx.xxx.xxx" 形式の文字列) -> Nwdiy::Packet::IPv4
#    (本クラス独自)
#    IPv4 アドレス形式の文字列から IPv4 アドレスを生成して返します。
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
# unicast? -> bool
# loopback? -> bool
# multicast? -> bool
#    (本クラス独自のメソッド)
#    アドレスの性質を返します
#
# broadcast?(mask) -> bool
#    (本クラス独自のメソッド)
#    ネットマスクあるいはマスク長を引数にとり、
#    ブロードキャストアドレスか否かを返します。
#
# included?(addr, mask) -> bool
#    (本クラス独自のメソッド)
#    アドレスとマスクを引数にとり、
#    インスタンスがその addr/mask 範囲内か否かを返します。
#
################################################################

require "spec_helper"
require "nwdiy/packet/ipv4addr"

RSpec.describe Nwdiy::Packet::IPv4Addr do
  test = { unicast: {
             byte: "\x0a\x01\x01\x01",
             name: "10.1.1.1",
             :unicast? => true,
             :loopback? => false,
             :multicast? => false },
           loopback: {
             byte: "\x7f\x00\x00\x01",
             name: "127.0.0.1",
             :unicast? => true,
             :loopback? => true,
             :multicast? => false },
           multicast: {
             byte: "\xe0\x00\x00\x05".force_encoding("ASCII-8BIT"),
             name: "224.0.0.5",
             :unicast? => false,
             :loopback? => false,
             :multicast? => true } }
  test.each do |theme, hash|
    [:byte, :name].each do |src|
      addr = hash[src]
      it "creates an #{theme} IPv4 addr from #{addr.dump}" do
        ip = Nwdiy::Packet::IPv4Addr.new(addr)
        expect(ip.to_s).to eq hash[:byte]
        expect(ip.inspect).to eq hash[:name]
        expect(ip.unicast?).to eq hash[:unicast?]
        expect(ip.loopback?).to eq hash[:loopback?]
        expect(ip.multicast?).to eq hash[:multicast?]
      end
    end
  end
end
