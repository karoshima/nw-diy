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
# new(name) => Nwdiy::Func::Ethernet
#    インターフェースを開きます。
#    通常は NW-DIY のなかで使える仮想的なインターフェースを開きます。
#    ただし、以下の条件に合致すると、OS のインターフェースを開きます。
#
#    a. name が OS のインターフェース名であること
#    b. Linux であること (AF_PACKET に対応していること)
#    c. 最初に root 権限で ethernet_proxy.rb を動かしてあること
#       あるいは本プログラム自身を root 権限で動かしていること
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
################################################################

require "spec_helper"
require "rbconfig"

RSpec.describe Nwdiy::Func::Out::Ethernet do
  it "has class methods" do
    expect(Nwdiy::Func::Out::Ethernet.respond_to?(:new)).to be true
  end

  it "has instance methods" do
    hoge = Nwdiy::Func::Out::Ethernet.new
    expect(hoge.on).to be true
    expect(hoge.power).to be true
    expect(hoge.off).to be false
    expect(hoge.power).to be false
    expect(hoge.respond_to?(:ready?)).to be true
    expect(hoge.respond_to?(:recv)).to be true
    expect(hoge.respond_to?(:send)).to be true
  end


  ifname = { sock: "dummy" }
  case RbConfig::CONFIG['host_os']
  when /linux/
    ifas = Socket::getifaddrs
    index = ifas.find {|ifp| ifp.name =~ /^lo/ }
    ifname[:lo] = ifas[index].name
  end

  ifname.values.each do |name|
    it "can open #{name}" do
      puts ifp = Nwdiy::Func::Out::Ethernet.new(name)
      expect(ifp).not_to be nil
    end
  end

  name = ifname[:sock]
  it "can send/recv Ethernet frame via #{name}" do

    frame = Nwdiy::Packet::Ethernet.new(src: "00:00:0e:00:00:01",
                                        dst: "00:00:0e:00:00:02")
    ifp0 = Nwdiy::Func::Out::Ethernet.new(name)
    ifp1 = Nwdiy::Func::Out::Ethernet.new(name)

    ifp0.on
    ifp1.on

    expect(ifp0.send(frame)).to be frame.bytesize
    expect(ifp1.recv.to_pkt).to eq frame.to_pkt
    expect { ifp0.send("hoge") }.to raise_error Nwdiy::Func::Out::Ethernet::EthError

  end

end

