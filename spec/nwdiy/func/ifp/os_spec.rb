#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# OS を表すインターフェース機能です。
# OS のイーサネットインターフェースを取り出したり、
# OS の TCP/UDP コネクションを作ったりします。
#
#【特異メソッド】
#
# new -> Nwdiy::Func::Ifp::OS
#    OS インスタンスを生成します。
#
#【定数】
#
# Nwdiy::OS
#    OS インターフェースは OS にひとつなので
#    NW-DIY アプリ起動時に生成してあります。
#
#【インスタンスメソッド】
#
# eth(name = nil) -> Nwdiy::Func::Ifp::Ethernet
#    インターフェース名を引数にとり、
#    イーサネットインターフェースを返します。
#
#    OS のイーサネットインターフェースの名称を引数として与え、
#    OS のイーサネットインターフェースを開く権限があるときは
#    そのインターフェースで送受信するインスタンスを返します。
#
#    引数が与えられなかったとき、
#    引数が OS のイーサネットインターフェース名ではないとき、
#    OS のイーサネットインターフェースを開く権限がないときは、
#    NW-DIY 内で使用できる仮想的なインターフェースインスタンスを
#    生成して返します。
#
# real_eth(name) -> Nwdiy::Func::Ifp::Ethernet
#    OS に実在するインターフェースのインスタンスを返します。
#
#    引数が OS のイーサネットインターフェース名でないときは、
#    Errno::ENOENT を返します。
#    OS のイーサネットインターフェースを開く権限がないときは、
#    Errno::EPERM を返します。
# 
# eth = ifp
#    OS にイーサネットインターフェースインスタンスを設定します。
#
# self | other
#    よく考えるとちょっと何言ってるのか分からない状況なので
#    無効化しています。NoMethodError になっちゃいます。
#
################################################################

require "spec_helper"

RSpec.describe Nwdiy::Func::Ifp::OS do
  it "has class methods" do
    expect(Nwdiy::Func::Ifp::OS.respond_to?(:new)).to be true
  end

  it "exists an static instance in Func" do
    expect(Nwdiy::OS).to be_a_kind_of(Nwdiy::Func::Ifp::OS)
  end

  it "has instance methods" do
    expect(Nwdiy::OS.off).to be false
    expect(Nwdiy::OS.power).to be false
    expect(Nwdiy::OS.on).to be true
    expect(Nwdiy::OS.power).to be true
    expect(Nwdiy::OS.respond_to?(:ready?)).to be false
    expect(Nwdiy::OS.respond_to?(:recv)).to be false
    expect(Nwdiy::OS.respond_to?(:send)).to be false
    expect(Nwdiy::OS.respond_to?(:|)).to be false
  end

  it "can open dummy interface" do
    ifp0 = Nwdiy::Func::Ifp::Ethernet.new
    expect(ifp0).not_to be nil
    ifp1 = Nwdiy::Func::Ifp::Ethernet.new(ifp0.name)
    expect(ifp1).not_to be nil
    
    ifp0.on
    ifp1.on

    frame = Nwdiy::Packet::Ethernet.new(src: "00:00:00:00:00:01",
                                        dst: "00:00:00:00:00:02")

    expect(ifp0.send(frame)).to be frame.bytesize
    expect(ifp0.sent).to be 1
    expect(ifp0.received).to be 0
    expect(ifp1.recv.to_pkt).to eq frame.to_pkt
    expect(ifp1.sent).to be 0
    expect(ifp1.received).to be 1

    expect { ifp0.send("hoge") }.to raise_error Nwdiy::Func::Ifp::Ethernet::EtherError

  end

  if RbConfig::CONFIG['host_os'] =~ /linux/
    it "check real interface" do
      ifas = Socket::getifaddrs
      lo = ifas.find {|ifp| ifp.name =~ /^lo/ }
      begin
        ifp = Nwdiy::OS.real_eth(lo.name)
        expect(ifp).not_to be nil
      rescue Errno::EPERM
      end
    end

    it "can check non-real interface does not exist" do
      expect { Nwdiy::OS.real_eth("hogehoge") }.to raise_error Errno::ENOENT
    end
  end
end
