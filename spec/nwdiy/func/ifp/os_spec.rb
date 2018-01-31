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
# eth(name) -> Nwdiy::Func::Ifp::Ethernet
#    OS が持っているインターフェース名を引数にとり、
#    イーサネットインターフェースを返します。
#
#    OS が持ってないインターフェース名を与えられたり、
#    OS のイーサネットインターフェースを開く機能や権限がないときは、
#    NW-DIY のなかでパケットを交換するための仮想的な
#    インターフェースを返します。
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

  ifname = { sock: "dummy" }
  if RbConfig::CONFIG['host_os'] =~ /linux/
    ifas = Socket::getifaddrs
    lo = ifas.find {|ifp| ifp.name =~ /^lo/ }
    ifname[:lo] = lo.name
  end

  ifname.values.each do |name|
    it "can open #{name}" do
      expect(Nwdiy::OS.link(name)).not_to be nil
    end
  end
end
