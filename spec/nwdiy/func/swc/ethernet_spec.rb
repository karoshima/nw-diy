#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Nwdiy::Packet::Ethernet パケットを L2 中継する機能です
#
#【特異メソッド】
#
# new(name = nil) -> Nwdiy::Func::Swc::Ethernet
#    イーサネットスイッチを作ります。
#    扱うことができるパケットは Nwdiy::Packet::Ethernet です。
#    それ以外のパケットは扱うことができません。
#
#【インスタンスメソッド】
#
# パケット中継系はすべて Nwdiy::Func::Swc を継承します。
#
# age = 秒
#    学習テーブルのタイムアウトを設定します。
#
# age -> Float|Integer
#    学習テーブルのタイムアウトを確認します。
#
################################################################

require "spec_helper"

Thread.abort_on_exception = true

RSpec.describe Nwdiy::Func::Swc::Ethernet do
  it "can transfer Ethernet frame" do

    p1, p2 = Nwdiy::Func::Out::Pipe.pair("p1", "p2")
    p3, p4 = Nwdiy::Func::Out::Pipe.pair("p3", "p4")

    sw = Nwdiy::Func::Swc::Ethernet.new("sw")
    
    p2 | sw | p3

    [p1, p2, p3, p4, sw].each { |p| p.on }

    # p1 から送った非イーサネットパケットは出てこない
    # p1 から送ったイーサネットパケットは p4 から出てくる
    bin = Nwdiy::Packet::Binary.new("hoge")
    eth = Nwdiy::Packet::Ethernet.new(src: { unicast: true } )
    expect(p1.send(bin)).to eq bin.bytesize
    expect(p1.send(eth)).to eq eth.bytesize
    expect(p4.recv.to_pkt).to eq eth.to_pkt
    expect(p1.ready?).to be false
  end

  it "can set/get timeout" do
    sw = Nwdiy::Func::Swc::Ethernet.new("sw")
    [ 300, 299.9 ].each do |age|
      expect(sw.age = age).to be age
      expect(sw.age).to be age
    end
  end

  it "can forward packet based on L2 forwarding table" do

    ################
    # 二股構成を組む

    p11, p12 = Nwdiy::Func::Out::Pipe.pair("p11", "p12")
    sw1 = Nwdiy::Func::Swc::Ethernet.new("sw1")
    p12 | sw1

    p21, p22 = Nwdiy::Func::Out::Pipe.pair("p21", "p22")
    sw2 = Nwdiy::Func::Swc::Ethernet.new("sw2")
    p22 | sw2

    p31, p32 = Nwdiy::Func::Out::Pipe.pair("p31", "p32")
    sw3 = Nwdiy::Func::Swc::Ethernet.new("sw3")
    p32 | sw3

    sw2 | sw1 | sw3

    [ sw1, p11, p12, sw2, p21, p22, sw3, p31, p32 ].each {|p| p.on }

    ################
    # 学習させる

    # p11 配下に 00:00:0e:00:00:11
    pkt = Nwdiy::Packet::Ethernet.new(dst: { broadcast: true })
    pkt.src = "00:00:0e:00:00:11"
    expect(p11.send(pkt)).to eq pkt.bytesize
    expect(p21.recv.to_pkt).to eq pkt.to_pkt
    expect(p31.recv.to_pkt).to eq pkt.to_pkt

    # p21 配下に 00:00:0e:00:00:21
    pkt.src = "00:00:0e:00:00:21"
    expect(p21.send(pkt)).to eq pkt.bytesize
    expect(p11.recv.to_pkt).to eq pkt.to_pkt
    expect(p31.recv.to_pkt).to eq pkt.to_pkt

    # p31 配下に 00:00:0e:00:00:31
    pkt.src = "00:00:0e:00:00:31"
    expect(p31.send(pkt)).to eq pkt.bytesize
    expect(p11.recv.to_pkt).to eq pkt.to_pkt
    expect(p21.recv.to_pkt).to eq pkt.to_pkt

    # p31 配下から p11 配下へ送信
    pkt.dst = "00:00:0e:00:00:11"
    expect(p31.send(pkt)).to eq pkt.bytesize
    expect(p11.recv.to_pkt).to eq pkt.to_pkt

    # p31 配下から p31 配下へ送信
    pkt.dst = "00:00:0e:00:00:31"
    expect(p31.send(pkt)).to eq pkt.bytesize

    # 他のインターフェースに余計なパケットは飛んでない
    # (最後のこのブロードキャストが届くこと)
    pkt.dst = "ff:ff:ff:ff:ff:ff"
    pkt.src = "00:00:0e:00:00:ff"
    pkt.data = "xxxx"
    expect(p11.send(pkt)).to eq pkt.bytesize
    expect(p21.recv.to_pkt).to eq pkt.to_pkt
    expect(p31.recv.to_pkt).to eq pkt.to_pkt
    expect(p21.send(pkt)).to eq pkt.bytesize
    expect(p11.recv.to_pkt).to eq pkt.to_pkt
    expect(p31.recv.to_pkt).to eq pkt.to_pkt
    expect(p31.send(pkt)).to eq pkt.bytesize
    expect(p21.recv.to_pkt).to eq pkt.to_pkt
    expect(p11.recv.to_pkt).to eq pkt.to_pkt

    ################
    # 学習テーブルの ageout はテストに時間かかるので、、、略
  end
end
