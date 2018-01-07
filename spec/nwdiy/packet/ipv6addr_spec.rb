#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# IPv6 アドレスのクラスです。
#
#【特異メソッド】
#
# new(16byteのバイト列) -> Nwdiy::Packet::IPv6Addr
#    (Nwdiy::Packet から継承)
#    バイト列から IPv6 アドレスインスタンスを生成して返します。
#
# new("xx:xx::xx" 形式の文字列) -> Nwdiy::Packet::IPv6Addr
#    (本クラス独自)
#    IPv6 アドレス形式の文字列から IPv6 アドレスを生成して返します。
#
#【インスタンスメソッド】
#
# to_pkt -> String
#    IPv6 アドレスをバイト列に変換します
#
# inspect -> String
#    IPv6 アドレスを可読形式で返します
#
# unicast? -> bool
# multicast? -> bool
# loopback? -> bool
# nodelocal? -> bool
# linklocal? -> bool
# global? -> bool
#    アドレスの性質を返します
#
# included?(addr, mask) -> bool
#    IPv6 アドレスとマスクを引数にとり
#    インスタンスがその addr/mask 範囲内か否かを返します。
#
################################################################

require "spec_helper"
RSpec.describe Nwdiy::Packet::IPv6Addr do
  test = { loopback: { 
             byte: [0, 0, 0, 1].pack("N4"),
             name: "::1",
             :unicast? => true,
             :loopback? => true },
           unicast_linklocal: {
             byte: [0xfe800000, 0, 0, 1].pack("N4"),
             name: "fe80::1",
             :unicast? => true,
             :linklocal? => true },
           unicast_global: {
             byte: [0x20010db8, 0, 0, 0x7f000001].pack("N4"),
             name: "2001:db8::7f00:1",
             :unicast? => true,
             :global? => true },
           multicast_nodelocal: {
             byte: [0xff010000, 0, 0, 1].pack("N4"),
             name: "ff01::1",
             :multicast? => true,
             :nodelocal? => true },
           multicast_linklocal: {
             byte: [0xff020000, 0, 0, 5].pack("N4"),
             name: "ff02::5",
             :multicast? => true,
             :linklocal? => true },
           multicast_global: {
             byte: [0xff0e0000, 0, 0, 5].pack("N4"),
             name: "ff0e::5",
             :multicast? => true,
             :global? => true } }
  test.each do |theme, hash|
    [:byte, :name].each do |src|
      addr = hash[src]
      it "creates an #{theme} IPv6 addr from #{hash[:name]} with #{src}" do
        ip = Nwdiy::Packet::IPv6Addr.new(addr)
        expect(ip.to_pkt).to eq hash[:byte]
        expect(ip.inspect).to eq hash[:name]
        expect(ip.unicast?).to eq !!hash[:unicast?]
        expect(ip.loopback?).to eq !!hash[:loopback?]
        expect(ip.nodelocal?).to eq !!hash[:nodelocal?]
        expect(ip.linklocal?).to eq !!hash[:linklocal?]
        expect(ip.global?).to eq !!hash[:global?]
        expect(ip.multicast?).to eq !!hash[:multicast?]
      end
    end
  end
end
