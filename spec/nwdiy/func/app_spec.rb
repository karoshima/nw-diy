#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# アプリケーションとしてパケットを送受信して何かをする機能です。
# 具体的には ARP や PING などパケットを自動送受信したり、
# STP や RIP, OSPF などのように経路情報を交換したり、
# トンネル端で鍵交換したり、サーバー負荷を監視したり、
# というアプリケーション機能になります。
#
#【特異メソッド】
#
# new(name = nil) => Nwdiy::Func::App
#    アプリを動かす箱をひとつ作ります。
#
#【インスタンスメソッド】
#
# attach(ifp) -> self
#    インタフェースを繋ぎます。
#    ひとつだけ繋ぐことができます。
#    (複数のインタフェースを繋ぐときは、L2スイッチで収容してください)
#
# attach_left(ifp) -> self
# attach_right(ifp) -> self
#    attach() への alias です。
#
# detach(ifp = 登録済ifp) -> 登録済ifp
#    繋いだインタフェースを抜きます。
#
################################################################

require "spec_helper"

Thread.abort_on_exception = true

RSpec.describe Nwdiy::Func::App do
  it "has instance methods" do
    hoge = Nwdiy::Func::App.new
    expect(hoge).to be_a_kind_of(Nwdiy::Func::App)
    expect(hoge.on).to be true
    expect(hoge.power).to be true
    expect(hoge.off).to be false
    expect(hoge.power).to be false

    pair = Nwdiy::Func::Ifp::Pipe.pair
    expect(hoge.attach(pair[0])).to be hoge
    expect(hoge.attached).to eq [pair[0]]
    expect(hoge.attached).to eq [pair[0]]
    expect { hoge.attach_left(pair[1]) }.to raise_error(Nwdiy::Func::App::Error)
    expect { hoge.attach_right(pair[1]) }.to raise_error(Nwdiy::Func::App::Error)
    expect(hoge.detach).to be pair[0]
    expect(hoge.attach_left(pair[1])).to be hoge
    expect(hoge.attached).to eq [pair[1]]
    expect { hoge.attach(pair[0]) }.to raise_error(Nwdiy::Func::App::Error)
    expect { hoge.detach(pair[0]) }.to raise_error(Nwdiy::Func::App::Error)
    expect(hoge.detach(pair[1])).to be pair[1]
  end

  it "can handle packet" do
    # テスト用クラス, ethernet の src, dst を入れ替えて返す
    class Reflector < Nwdiy::Func::App
      def initialize
        super
        @thread = nil
      end
      def on
        if @thread
          self.off
        end
        @thread = Thread.new do
          begin
            loop do
              pkt = self.attached[0].recv
              pkt.src, pkt.dst = pkt.dst, pkt.src
              self.attached[0].send pkt
            end
          rescue EOFError
          end
        end
      end
      def off
        @thread.kill if @thread
        @thread = nil
      end
    end

    ref = Reflector.new
    p0, p1 = Nwdiy::Func::Ifp::Pipe.pair.each {|p| p.on }
    p1 | ref
    ref.on

    pkt0 = Nwdiy::Packet::Ethernet.new(src: "00:00:00:00:00:01",
                                       dst: "00:00:00:00:00:02")
    p0.send(pkt0)
    pkt1 = p0.recv
    expect(pkt1.src.inspect).to eq "00:00:00:00:00:02"
    expect(pkt1.dst.inspect).to eq "00:00:00:00:00:01"
  end
end
