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

    ifp1, ifp2 = Nwdiy::Func::Ifp::Pipe.pair
    ifp3, ifp4 = Nwdiy::Func::Ifp::Pipe.pair
    ifp5, ifp6 = Nwdiy::Func::Ifp::Pipe.pair
    ifp7, ifp8 = Nwdiy::Func::Ifp::Pipe.pair

    ifp2 | bc | ifp4
    ifp6 | bc | ifp8

    [ifp1, ifp2, ifp3, ifp4, ifp5, ifp6, ifp7, ifp8, bc].each {|p| p.on }

    pkt = Nwdiy::Packet::Ethernet.new

    # ifp1 から送ったら、ifp3, ifp5, ifp7 に来る
    expect(ifp1.send(pkt)).to eq pkt.bytesize
    expect(ifp7.recv.to_pkt).to eq pkt.to_pkt
    expect(ifp5.recv.to_pkt).to eq pkt.to_pkt
    expect(ifp3.recv.to_pkt).to eq pkt.to_pkt
    expect(ifp1.ready?).to be false
    # パケットが流れたところの統計は 1
    expect(ifp1.sent).to be 1
    expect(ifp2.received).to be 1
    expect(ifp4.sent).to be 1
    expect(ifp6.sent).to be 1
    expect(ifp8.sent).to be 1
    expect(ifp3.received).to be 1
    expect(ifp5.received).to be 1
    expect(ifp7.received).to be 1
    # 逆方向の統計は 0
    expect(ifp1.received).to be 0
    expect(ifp2.sent).to be 0
    expect(ifp4.received).to be 0
    expect(ifp6.received).to be 0
    expect(ifp8.received).to be 0
    expect(ifp3.sent).to be 0
    expect(ifp5.sent).to be 0
    expect(ifp7.sent).to be 0

    # 逆に ifp7 から送ったら、ifp1, ifp3, ifp5 に来る
    expect(ifp7.send(pkt)).to eq pkt.bytesize
    expect(ifp1.recv.to_pkt).to eq pkt.to_pkt
    expect(ifp3.recv.to_pkt).to eq pkt.to_pkt
    expect(ifp5.recv.to_pkt).to eq pkt.to_pkt
    expect(ifp7.ready?).to be false
    # パケットが流れた数
    expect(ifp1.sent).to be 1
    expect(ifp1.received).to be 1
    expect(ifp2.sent).to be 1
    expect(ifp2.received).to be 1
    expect(ifp3.sent).to be 0
    expect(ifp3.received).to be 2
    expect(ifp4.sent).to be 2
    expect(ifp4.received).to be 0
    expect(ifp5.sent).to be 0
    expect(ifp5.received).to be 2
    expect(ifp6.sent).to be 2
    expect(ifp6.received).to be 0
    expect(ifp7.sent).to be 1
    expect(ifp7.received).to be 1
    expect(ifp8.sent).to be 1
    expect(ifp8.received).to be 1
  end
end
