#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# システム外部とパケットを送受信するネットワーク機能です。
#
# NW-DIY プロセスの外とパケットの交換をすることができます。
# NW-DIY 機器の外部とパケットの交換をすることもできます (注1)。
#
#【特異メソッド】
#
# new(name) => Nwdiy::Func::Out
#    インターフェースを開きます。
#    通常は NW-DIY のなかで使える仮想的なインターフェースを開きます。
#    ただし、以下の条件に合致すると、OS のインターフェースを開きます。
#
#    a. name が OS のインターフェース名であること
#    b. Linux であること (AF_PACKET に対応していること)
#    c. 最初に root 権限で ethernet_proxy.rb を動かしてあること
#       あるいは本プログラム自身を root 権限で動かしていること
#
# pair => Nwdiy::Func::Out, Nwdiy::Func::Out
#    ふたつのインターフェースを開きます。
#    ここで返されるふたつのインターフェースは繋がっています。
#
#【スーパークラスから継承されるインスタンスメソッド】
#
# on -> true(up)/false(down)
# off -> false
#    リンクアップあるいはリンクダウンさせます。
#    リンク状態を返します。
#
# power -> true(up)/false(down)
#    リンク状態を返します。
#
#【本クラス独自のインスタンスメソッド】
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
################################################################

require "spec_helper"

RSpec.describe Nwdiy::Func::Out do
  it "has class methods" do
    expect(Nwdiy::Func::Out.respond_to?(:new)).to be true
    expect(Nwdiy::Func::Out.respond_to?(:pair)).to be true
  end

  it "has instance methods" do
    hoge = Nwdiy::Func::Out.new("hoge")
    expect(hoge).to be_a_kind_of(Nwdiy::Func::Out)
    expect(hoge.on).to be true
    expect(hoge.power).to be true
    expect(hoge.off).to be false
    expect(hoge.power).to be false
    Nwdiy::Func::Out.stop_daemon
  end

  it "act as pair" do
    foo, bar = Nwdiy::Func::Out.pair
    expect(foo.on).to be true
    expect(bar.on).to be true

    pkt = Nwdiy::Packet::Ethernet.new
    pkt.dst = "00:00:0e:00:00:01"
    pkt.src = "00:00:0e:00:00:02"

    expect(foo.ready?).to be false
    expect(bar.send(pkt)).to eq pkt.bytesize
    expect(foo.ready?).to be true
    pkt2 = foo.recv
    expect(pkt2.to_pkt).not_to be pkt.to_pkt
    expect(pkt2.to_pkt).to eq pkt.to_pkt
  end

  it "must check on/off status" do
    foo, bar = Nwdiy::Func::Out.pair
    expect(foo.on).to be true
    expect(bar.on).to be true

    pkt = Nwdiy::Packet::Ethernet.new
    pkt.dst = "00:00:0e:00:00:01"
    pkt.src = "00:00:0e:00:00:02"

    expect(foo.ready?).to be false
    expect(bar.send(pkt)).to eq pkt.bytesize
    foo.off
    expect(foo.ready?).to be false
    expect(foo.recv).to be nil
    foo.on
    expect(foo.ready?).to be false
    expect(bar.send(pkt)).to eq pkt.bytesize
    expect(foo.ready?).to be true
    expect(foo.recv.to_pkt).to eq pkt.to_pkt
    expect(foo.ready?).to be false
  end
end
