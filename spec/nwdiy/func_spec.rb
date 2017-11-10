#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# 各種ネットワーク機能の抽象クラスです。
# ネットワーク機能は以下の抽象クラスに分類できます。
# 以下の抽象クラスはいずれも本クラス (Nwdiy::Func) の子クラスです。
#
# Nwdiy::Func::Out (outer)
#   NW-DIY システムの外部と通信する機能です
#   具体的には、NW-DIY を動かしている機器についている
#   イーサネットインターフェースです。
#
# Nwdiy::Func::App (application)
#   アプリケーションとしてパケットを送受信して何かをする機能です。
#   具体的には ARP や PING などパケットを自動送受信したり、
#   STP や RIP, OSPF などのように経路情報を交換したり、
#   トンネル端で鍵交換したり、サーバー負荷を監視したり、
#   というアプリケーション機能になります。
#
# Nwdiy::Func::Spl (splitter)
#   ヘッダ情報に沿ってパケットをレイヤ分けして、上位層に渡します。
#   上位層から来たパケットには、ヘッダを被せて下位層に渡します。
#   具体的には tagged VLAN による LAN 分割, IP proto や TCP/UDP
#   ポート番号による各種プロトコルへの紐付けなどがあります。
#
# Nwdiy::Func::Swc (switcher)
#   ヘッダ情報に沿ってパケットの行先を決め、交通整理します。
#
# Nwdiy::Func::Sct (scatter)
#    トラフィックを負荷などに応じて分散します。
#
# Nwdiy::Func::Flt (filter)
#    トラフィックを監視したりフィルタしたり整形したりします。
#
################################################################
#
#【子クラスの特異メソッド】
#
# new -> Nwdiy::Func の子クラスのインスタンス
#    ネットワーク機能をもった機器 (インスタンス) を生成します。
#
#【子クラスのインスタンスメソッド】
#
# on -> true(電源ON)/false(電源OFF)
# off -> false(電源OFF)
#    機器の稼動状態を設定します。
#    稼動状況を返します。
#
# power -> true(電源ON)/false(電源OFF)
#    機器の稼動状態を返します。
#
# attach_left(ifp) -> self
# attach_right(ifp) -> self
# attach(ifp) -> self (Nwdiy::Func::Flt を除く)
#    インタフェースをインスタンスの左側あるいは右側に接続します。
#    ただし、Nwdiy::Func::Flt のみが本当に左右を区別するので、
#    他のクラスでは attach(ifp) で代替できます。
#
# attached -> [ifp, ifp, ifp, ...]
#    上記の attach で登録したインタフェースのリスト
#    
# detach(ifp) -> ifp
#    インタフェースをインスタンスから抜きます。
#
# self | other -> other
#    Nwdiy::Packet 子クラスのインスタンスである other を
#    パイプで繋ぎます。
#
################################################################

require "spec_helper"

Thread.abort_on_exception = true

RSpec.describe Nwdiy::Func do
  it "has some methods" do
    func = Nwdiy::Func.new
    expect(func.respond_to?(:on)).to be true
    expect(func.respond_to?(:off)).to be true
    expect(func.respond_to?(:power)).to be true
    expect(func.respond_to?(:attach_left)).to be true
    expect(func.respond_to?(:attach_right)).to be true
    expect(func.respond_to?(:detach)).to be true
  end

  it "returns dummy results" do
    func = Nwdiy::Func.new
    expect(func.on).to be true
    expect(func.power).to be true
    expect(func.off).to be false
    expect(func.power).to be false
    expect { func.attach_left(nil) }.to raise_error(NotImplementedError)
    expect { func.attach_right(nil) }.to raise_error(NotImplementedError)
    expect { func.detach(nil) }.to raise_error(NotImplementedError)
  end

  it "can chain with pipe('|')" do
    # サンプル機能
    # 単純に左右に渡すだけ
    # 動的なことは考慮してないので開発の参考にはしないでね
    class Hoge < Nwdiy::Func
      def initialize
        super
        @left
        @right
        @l2r
        @r2l
        @queue = Thread::Queue.new
      end
      def attach_left(out)
        @left = out
      end
      def attach_right(out)
        @right = out
      end
      def forward(a, b)
        Thread.new(a, b) do |ifa, ifb|
          @queue.push(nil)
          loop do
            ifb.send(ifa.recv)
          end
        end
      end
      def on
        self.off
        @l2r = self.forward(@left, @right)
        @r2l = self.forward(@right, @left)
        @queue.pop
        @queue.pop
      end
      def off
        if @l2r
          @l2r.kill
          @l2r = nil
        end
        if @r2l
          @r2l.kill
          @r2l = nil
        end
      end
    end

    foo = Hoge.new
    bar = Hoge.new

    p1, p2 = Nwdiy::Func::Out.pair
    p3, p4 = Nwdiy::Func::Out.pair

    [p1, p2, p3, p4].each {|p| p.on }

    p2 | foo | bar | p3

    foo.on
    bar.on

    pkt = Nwdiy::Packet::Ethernet.new
    pkt.dst = "00:00:0e:00:00:01"
    pkt.src = "00:00:0e:00:00:02"

    expect(p1.send(pkt)).to eq pkt.bytesize
    expect(p4.recv.to_pkt).to eq pkt.to_pkt

    [p1, p2, p3, p4, foo, bar].each {|p| p.off }
  end
end
