#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# フィルター系ネットワーク機能の抽象クラスです。
# 左右のネットワークを繋いでパケットを導通させ、
# そこを通るパケットに対して何がしかの処理を行ないます。
#
# 具体的にはアクセスコントロール, ファイヤーウォール, NAT, QoS
# などの機能を挙げることができます。
#
#【特異メソッド】
#
# new(name = nil) -> Nwdiy::Func::Flt
#    アプリを動かす箱をひとつ作ります。
#
#【インスタンスメソッド】
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
#    インタフェースをインスタンスの左側あるいは右側に接続します。
#    既にインターフェースが挿さっている場合は、挿し替えになります。
#
# attached -> [左ifp, 右ifp]
#    左右に挿さっているインターフェースを返します。
#
# detach_left -> 左ifp
# detach_right -> 右ifp
#    左あるいは右に挿さっていたインターフェースを返します。
#    抜けた状態で返されます。
#
# self | other -> other
#    Nwdiy::Packet 子クラスのインスタンスである other を
#    パイプで右側に繋ぎます。
#
#【内部に定義すべきインスタンスメソッド】
#
# forward(pkt) -> 出力パケット, 出力パケット, ...
#
#    受信したパケットである pkt に対して
#    ネットワーク機能としての処理を施して、
#    送出するパケットを返します。
#    nil を返すと、パケットの送信は行ないません。
#
#    左右の両方にパケットを送出するときには
#    メソッドの返り値として、それぞれのパケットを返してください。
#    これは例えば、ファイヤーウォールが TCP を切断するときに
#    送信元と宛先の双方に RST を送信するような場合に使える方法です。
#
#    受信したパケットの from と to は事前に設定してあります。
#    パケットの出力先を変えるときは、to を再設定して返してください。
#
################################################################

require "spec_helper"

Thread.abort_on_exception = true

RSpec.describe Nwdiy::Func::Flt do
  it "has some methods" do
    flt = Nwdiy::Func::Flt.new
    expect(flt.respond_to?(:on)).to be true
    expect(flt.respond_to?(:off)).to be true
    expect(flt.respond_to?(:power)).to be true
    expect(flt.respond_to?(:attach_left)).to be true
    expect(flt.respond_to?(:attach_right)).to be true
    expect(flt.respond_to?(:attached)).to be true
    expect(flt.respond_to?(:detach_left)).to be true
    expect(flt.respond_to?(:detach_right)).to be true
    expect(flt.respond_to?(:|)).to be true
  end

  it "can check ARP" do
    # サンプル機能
    # ARP の数をかぞえる
    # 動的なことは考慮してないので開発の参考にはしないでね
    class ARPCounter < Nwdiy::Func::Flt

      @count
      attr_reader :count

      def initialize
        super
        @count = Hash.new { 0 }
      end

      def forward(pkt)
        @count[pkt.from] += 1 if pkt.type == 0x0806
        return pkt
      end
    end

    flt = ARPCounter.new

    p1, p2 = Nwdiy::Func::Out::Pipe.pair
    p3, p4 = Nwdiy::Func::Out::Pipe.pair

    p2 | flt | p3

    [flt, p1, p2, p3, p4].each {|p| p.on }

    pkt = Nwdiy::Packet::Ethernet.new

    # p1 から送ったら p2→count→p3 と通って p4 から出てくるはず
    expect(p1.send(pkt)).to eq pkt.bytesize
    expect(p4.recv.to_pkt).to eq pkt.to_pkt

    # まだ ICMP は数えられていない
    expect(flt.count[p2]).to eq 0
    expect(flt.count[p3]).to eq 0

    # p4 から送ったら p3→count→p2 と通って p1 から出てくるはず
    expect(p4.send(pkt)).to eq pkt.bytesize
    expect(p1.recv.to_pkt).to eq pkt.to_pkt

    # まだ ARP は数えられていない
    expect(flt.count[p2]).to eq 0
    expect(flt.count[p3]).to eq 0

    # パケットに ARP データを載せたら、計上されるはず
    pkt.data = Nwdiy::Packet::ARP.new
    expect(p1.send(pkt)).to eq pkt.bytesize
    expect(p4.recv.to_pkt).to eq pkt.to_pkt
    expect(flt.count[p2]).to eq 1
    expect(flt.count[p3]).to eq 0
    expect(p4.send(pkt)).to eq pkt.bytesize
    expect(p1.recv.to_pkt).to eq pkt.to_pkt
    expect(flt.count[p2]).to eq 1
    expect(flt.count[p3]).to eq 1

    # パケットが ARP 以外だったら計上されない
    pkt.type = 0x0800
    expect(p1.send(pkt)).to eq pkt.bytesize
    expect(p4.recv.to_pkt).to eq pkt.to_pkt
    expect(flt.count[p2]).to eq 1
    expect(flt.count[p3]).to eq 1
    expect(p4.send(pkt)).to eq pkt.bytesize
    expect(p1.recv.to_pkt).to eq pkt.to_pkt
    expect(flt.count[p2]).to eq 1
    expect(flt.count[p3]).to eq 1

  end
end
