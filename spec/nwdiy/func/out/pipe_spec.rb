#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Nwdiy::Func 間でパケットを送受信するネットワーク機能です。
#
#【特異メソッド】
#
# pair -> [Nwdiy::Func::Out::Pair, Nwdiy::Func::Out::Pair]
#    内部で繋がったふたつのインタフェースを返します。
#    一方からパケットを流し込むと、もう一方から受信できます。
#
#【インスタンスメソッド】
#
# ready? -> bool
#    パケットが届いているか、すぐに返せるかどうかを返します。
#
# recv -> obj
#    パケットがひとつ届くまで待ち、
#    届いたパケットを返します。
#    リンクダウンしていれば nil を返します。
#
# send(packet) -> Integer
#    パケットを送信します。
#    パケットサイズを返します。
#
# sent -> Integer
#    送信したパケットの数を返す
#
# received -> Integer
#    受信したパケットの数を返す
#
################################################################

require "spec_helper"

RSpec.describe Nwdiy::Func::Out::Pipe do
  it "has class methods" do
    expect(Nwdiy::Func::Out::Pipe.respond_to?(:pair)).to be true
  end

  it "has instance methods" do
    ifps = Nwdiy::Func::Out::Pipe.pair
    ifps.each do |ifp|
      expect(ifp.power).to be true
      expect(ifp.respond_to?(:ready?)).to be true
      expect(ifp.respond_to?(:recv)).to be true
      expect(ifp.respond_to?(:send)).to be true
    end
  end

  it "can pass packets" do
    # テスト用パケット
    class Pkt < Nwdiy::Packet
      def_head :byte64, :name
    end

    pkt0 = Pkt.new("hoge")

    ifps = Nwdiy::Func::Out::Pipe.pair
    expect(ifps[0].ready?).to be false
    expect(ifps[1].ready?).to be false
    expect(ifps[0].sent).to be 0
    expect(ifps[0].received).to be 0
    expect(ifps[1].sent).to be 0
    expect(ifps[1].received).to be 0
    expect(ifps[0].send(pkt0)).to eq pkt0.bytesize
    expect(ifps[0].sent).to be 1
    expect(ifps[0].received).to be 0
    expect(ifps[1].sent).to be 0
    expect(ifps[1].received).to be 0
    expect(ifps[0].ready?).to be false
    expect(ifps[1].ready?).to be true
    pkt1 = ifps[1].recv
    expect(pkt1.to_pkt).to eq pkt0.to_pkt
    expect(ifps[0].sent).to be 1
    expect(ifps[0].received).to be 0
    expect(ifps[1].sent).to be 0
    expect(ifps[1].received).to be 1
  end
end
