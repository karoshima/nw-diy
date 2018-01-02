#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# スイッチ系ネットワーク機能の抽象クラスです。
# いくつかのネットワークを繋いでパケットを導通させ、
# パケットヘッダを元に適切なネットワークにパケットを流します。
#
#【特異メソッド】
#
# new(name = nil) -> Nwdiy::Func::Swc
#    スイッチ箱ひとつ作ります。
#
#【インスタンスメソッド】
#
# on -> true(電源ON)/false(電源OFF)
# off -> false(電源OFF)
#    機器の稼動状態を設定します。
#    稼動状況を返します。
#
# power -> true(電源ON)/false(電源OFF)
#    稼動状況を返します。
#
# attach(ifp) -> self
#    インターフェースをインスタンスに追加接続します。
#
# attach_left(ifp) -> self
# attach_right(ifp) -> self
#    attach(ifp) のエイリアスです。
#
# attached -> [インターフェース, インターフェース, ...]
#    繋がってるインターフェースの配列を返します。
#
# detach(ifp) -> ifp
#    繋がってるインターフェースを抜きます。
#    インターフェース ifp が繋がってなかったら、なにもせず nil を返します。
#
# self | other -> other
#    Nwdiy::Func 子クラスのインスタンスである other を
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
#    受信したパケットの from は設定してありますが、
#    to は設定してありません。
#    送出先インターフェースを設定してから返してください。
#
################################################################

require "spec_helper"

Thread.abort_on_exception = true

RSpec.describe Nwdiy::Func::Swc do
  it "has some methods" do
    swc = Nwdiy::Func::Swc.new
    expect(swc.respond_to?(:on)).to be true
    expect(swc.respond_to?(:off)).to be true
    expect(swc.respond_to?(:power)).to be true
    expect(swc.respond_to?(:attach_left)).to be true
    expect(swc.respond_to?(:attach_right)).to be true
    expect(swc.respond_to?(:attached)).to be true
    expect(swc.respond_to?(:detach)).to be true
    expect(swc.respond_to?(:|)).to be true
  end

  it "can broadcast packets" do
    # サンプル機能
    # パケットをブロードキャストする
    # 動的なことは考慮してないので開発の参考にはしないでね
    class BC < Nwdiy::Func::Swc
      def forward(inpkt)
        (self.attached - [inpkt.from]).map do |ifp|
          outpkt = inpkt.dup
          outpkt.to = ifp
          outpkt
        end
      end
    end
    bc = BC.new

    p1, p2 = Nwdiy::Func::Out::Pipe.pair
    p3, p4 = Nwdiy::Func::Out::Pipe.pair
    p5, p6 = Nwdiy::Func::Out::Pipe.pair
    p7, p8 = Nwdiy::Func::Out::Pipe.pair

    p2 | bc | p4
    p6 | bc | p8

    [p1, p2, p3, p4, p5, p6, p7, p8, bc].each {|p| p.on }

    pkt = Nwdiy::Packet::Ethernet.new

    # p1 から送ったら、p3, p5, p7 に来る
    expect(p1.send(pkt)).to eq pkt.bytesize
    expect(p7.recv.to_pkt).to eq pkt.to_pkt
    expect(p5.recv.to_pkt).to eq pkt.to_pkt
    expect(p3.recv.to_pkt).to eq pkt.to_pkt
    expect(p1.ready?).to be false
    # パケットが流れたところの統計は 1
    expect(p1.sent).to be 1
    expect(p2.received).to be 1
    expect(p4.sent).to be 1
    expect(p6.sent).to be 1
    expect(p8.sent).to be 1
    expect(p3.received).to be 1
    expect(p5.received).to be 1
    expect(p7.received).to be 1
    # 逆方向の統計は 0
    expect(p1.received).to be 0
    expect(p2.sent).to be 0
    expect(p4.received).to be 0
    expect(p6.received).to be 0
    expect(p8.received).to be 0
    expect(p3.sent).to be 0
    expect(p5.sent).to be 0
    expect(p7.sent).to be 0

    # 逆に p7 から送ったら、p1, p3, p5 に来る
    expect(p7.send(pkt)).to eq pkt.bytesize
    expect(p1.recv.to_pkt).to eq pkt.to_pkt
    expect(p3.recv.to_pkt).to eq pkt.to_pkt
    expect(p5.recv.to_pkt).to eq pkt.to_pkt
    expect(p7.ready?).to be false
    # パケットが流れた数
    expect(p1.sent).to be 1
    expect(p1.received).to be 1
    expect(p2.sent).to be 1
    expect(p2.received).to be 1
    expect(p3.sent).to be 0
    expect(p3.received).to be 2
    expect(p4.sent).to be 2
    expect(p4.received).to be 0
    expect(p5.sent).to be 0
    expect(p5.received).to be 2
    expect(p6.sent).to be 2
    expect(p6.received).to be 0
    expect(p7.sent).to be 1
    expect(p7.received).to be 1
    expect(p8.sent).to be 1
    expect(p8.received).to be 1
  end
end
