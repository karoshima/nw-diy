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

    ifp1, ifp2 = Nwdiy::Func::Ifp::Pipe.pair
    ifp3, ifp4 = Nwdiy::Func::Ifp::Pipe.pair

    sw = Nwdiy::Func::Swc::Ethernet.new("sw")
    
    ifp2 | sw | ifp3

    [ifp1, ifp2, ifp3, ifp4, sw].each { |p| p.on }

    # ifp1 から送った非イーサネットパケットは出てこない
    # ifp1 から送ったイーサネットパケットは ifp4 から出てくる
    bin = Nwdiy::Packet::Binary.new("hoge")
    eth = Nwdiy::Packet::Ethernet.new(src: { unicast: true } )
    expect(ifp1.send(bin)).to eq bin.bytesize
    expect(ifp1.send(eth)).to eq eth.bytesize
    expect(ifp4.recv.to_pkt).to eq eth.to_pkt
    expect(ifp1.ready?).to be false
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

    ifp11, ifp12 = Nwdiy::Func::Ifp::Pipe.pair
    sw1 = Nwdiy::Func::Swc::Ethernet.new("sw1")
    ifp12 | sw1

    ifp21, ifp22 = Nwdiy::Func::Ifp::Pipe.pair
    sw2 = Nwdiy::Func::Swc::Ethernet.new("sw2")
    ifp22 | sw2

    ifp31, ifp32 = Nwdiy::Func::Ifp::Pipe.pair
    sw3 = Nwdiy::Func::Swc::Ethernet.new("sw3")
    ifp32 | sw3

    sw2 | sw1 | sw3

    [ sw1, ifp11, ifp12, sw2, ifp21, ifp22, sw3, ifp31, ifp32 ].each {|p| p.on }

    ################
    # 学習させる

    # ifp11 配下に 00:00:0e:00:00:11
    pkt = Nwdiy::Packet::Ethernet.new(dst: { broadcast: true })
    pkt.src = "00:00:0e:00:00:11"
    expect(ifp11.send(pkt)).to eq pkt.bytesize
    expect(ifp21.recv.to_pkt).to eq pkt.to_pkt
    expect(ifp31.recv.to_pkt).to eq pkt.to_pkt

    # ifp21 配下に 00:00:0e:00:00:21
    pkt.src = "00:00:0e:00:00:21"
    expect(ifp21.send(pkt)).to eq pkt.bytesize
    expect(ifp11.recv.to_pkt).to eq pkt.to_pkt
    expect(ifp31.recv.to_pkt).to eq pkt.to_pkt

    # ifp31 配下に 00:00:0e:00:00:31
    pkt.src = "00:00:0e:00:00:31"
    expect(ifp31.send(pkt)).to eq pkt.bytesize
    expect(ifp11.recv.to_pkt).to eq pkt.to_pkt
    expect(ifp21.recv.to_pkt).to eq pkt.to_pkt

    # ifp31 配下から p11 配下へ送信
    pkt.dst = "00:00:0e:00:00:11"
    expect(ifp31.send(pkt)).to eq pkt.bytesize
    expect(ifp11.recv.to_pkt).to eq pkt.to_pkt

    # ifp31 配下から p31 配下へ送信
    pkt.dst = "00:00:0e:00:00:31"
    expect(ifp31.send(pkt)).to eq pkt.bytesize

    # 他のインターフェースに余計なパケットは飛んでない
    # (最後のこのブロードキャストが届くこと)
    pkt.dst = "ff:ff:ff:ff:ff:ff"
    pkt.src = "00:00:0e:00:00:ff"
    pkt.data = "xxxx"
    expect(ifp11.send(pkt)).to eq pkt.bytesize
    expect(ifp21.recv.to_pkt).to eq pkt.to_pkt
    expect(ifp31.recv.to_pkt).to eq pkt.to_pkt
    expect(ifp21.send(pkt)).to eq pkt.bytesize
    expect(ifp11.recv.to_pkt).to eq pkt.to_pkt
    expect(ifp31.recv.to_pkt).to eq pkt.to_pkt
    expect(ifp31.send(pkt)).to eq pkt.bytesize
    expect(ifp21.recv.to_pkt).to eq pkt.to_pkt
    expect(ifp11.recv.to_pkt).to eq pkt.to_pkt

    ################
    # 学習テーブルの ageout はテストに時間かかるので、、、略
  end
end
