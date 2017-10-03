#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# MAC アドレスのクラスです。
#
#【特異メソッド】
# new(6byteのバイト列) -> Nwdiy::Packet::Mac
#    (Nwdiy::Pacet から継承)
#    バイト列から Mac アドレスインスタンスを生成して返します。
#
# new("xx:xx:xx:xx:xx:xx" 形式の文字列) -> Nwdiy::Packet::Mac
#    (本クラス独自)
#    Mac アドレス形式の文字列から Mac アドレスを生成して返します。
#
# new(Hash) -> Nwdiy::Packet::Mac
#    (本クラス独自のメソッド)
#    乱数で Mac アドレスインスタンスを生成して返します。
#    Hash において属性に対する値が true であれば、
#    その属性を持ったインスタンスを作成します。
#    Hash のキーに指定できる属性は以下のものです。
#
#      :unicast =>    ユニキャスト (multicast, broadcast と排他)
#      :multicast =>  マルチキャスト (unicast と排他)
#      :broadcast =>  ブロードキャスト (unicast と排他)
#      :global =>     グローバルアドレス (local と排他)
#      :local =>      ローカルアドレス (global と排他)
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
# multicast? -> bool
# broadcast? -> bool
# global? -> bool
# local? -> bool
#    (本クラス独自のメソッド)
#    アドレスの性質を返します
#
################################################################

require "spec_helper"

RSpec.describe Nwdiy::Packet::MacAddr do
  test = { unicast: {
             byte: "\x00\x00\x0e\x01\x02\x03",
             name: "00:00:0e:01:02:03",
             :unicast? => true,
             :multicast? => false,
             :broadcast? => false,
             :global? => true,
             :local? => false },
           multicast: {
             byte: "\x01\x00\x0e\x01\x02\x03",
             name: "01:00:0e:01:02:03",
             :unicast? => false,
             :multicast? => true,
             :broadcast? => false,
             :global? => true,
             :local? => false },
           broadcast: {
             byte: "\xff\xff\xff\xff\xff\xff".force_encoding("ASCII-8BIT"),
             name: "ff:ff:ff:ff:ff:ff",
             :unicast? => false,
             :multicast? => true,
             :broadcast? => true,
             :global? => true,
             :local? => false },
           global: {
             byte: "\x00\x00\x0e\x01\x02\x03",
             name: "00-00-0e-01-02-03",
             :unicast? => true,
             :multicast? => false,
             :broadcast? => false,
             :global? => true,
             :local? => false },
           local: {
             byte: "\x02\x00\x0e\x01\x02\x03",
             name: "02.00.0e.01.02.03",
             :unicast? => true,
             :multicast? => false,
             :broadcast? => false,
             :global? => false,
             :local? => true } }

  test.each do |theme, hash|
    [ :byte, :name ].each do |src|
      addr = hash[src]
      it "creates an #{theme} Mac addr from #{addr.dump}" do
        mac = Nwdiy::Packet::MacAddr.new(addr)
        expect(mac.to_s).to eq hash[:byte]
        expect(mac.inspect).to eq hash[:name].gsub(/[\.\-]/, ":")
        expect(mac.unicast?).to be hash[:unicast?]
        expect(mac.multicast?).to be hash[:multicast?]
        expect(mac.broadcast?).to be hash[:broadcast?]
        expect(mac.global?).to be hash[:global?]
        expect(mac.local?).to be hash[:local?]
      end
    end
  end

  [nil, true, false].each do |uni|
    [nil, true, false].each do |multi|
      [nil, true, false].each do |broad|
        [nil, true, false].each do |global|
          [nil, true, false].each do |local|
            hash = { unicast: uni, multicast: multi, broadcast: broad,
                     global: global, local: local }
            error = (uni && (multi || broad)) || (global && local) || (broad && local)
            if error
              it "fails to create Ethernet frame on #{uni},#{multi},#{broad},#{global},#{local}" do
                expect { Nwdiy::Packet::MacAddr.new(hash) }.to raise_error(TypeError)
              end
            else
              it "can create Ethernet frame on #{uni},#{multi},#{broad},#{global},#{local}" do
                mac = Nwdiy::Packet::MacAddr.new(hash)
                expect(mac).to be_a(Nwdiy::Packet::MacAddr)
              end
            end
          end
        end
      end
    end
  end
end
