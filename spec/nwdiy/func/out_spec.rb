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
#    b. Linux であること (PCAP 未対応であり AF_PACKET で実装しているため)
#    c. 最初に root 権限で ethernet_proxy.rb を動かしてあること
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
    puts Nwdiy::Func::Out
    hoge = Nwdiy::Func::Out.new("hoge")
    expect(hoge).to be_a_kind_of(Nwdiy::Func::Out)
    expect(hoge.on).to be true
    expect(hoge.power).to be true
    expect(hoge.off).to be false
    expect(hoge.power).to be false
    Nwdiy::Func::Out.stop_daemon
  end

  # it "act as pair" do
  #   foo, bar = Nwdiy::Func::Out.pair
  #   expect(foo.on).to be true
  #   expect(bar.on).to be true

  #   pkt = "Hello world"
  #   expect(foo.ready?).to be false
  #   expect(bar.send(pkt)).to be pkt.bytesize
  #   expect(foo.ready?).to be true
  #   expect(foo.recv).to eq pkt
  # end
end
