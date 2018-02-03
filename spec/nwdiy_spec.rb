#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# ruby 版 NW-DIY のトップモジュール
#
# いろんなネットワーク機能をモデル化することで、
# レイヤごとの処理を明快に定義することができるようになります。
#
# ネットワーク機能を大別すると、パケットそのものの振舞いを定義した
# パケットモジュールと、パケットの扱いを定義した機能モジュールの
# 二種類に分けることができます。機能モジュールは
#
# Nwdiy::Packet
#
#    パケットそのものの構成や振舞いを定義したパケットモジュールです。
#    バイナリデータとの相互変換や、
#    データの梱包あるいは梱包したデータの取り出し、
#    文字列表現などがあります。
#
# Nwdiy::Work
#
#    パケットの特定のレイヤ (パケット種別) を処理する機能モジュールです。
#    たとえば L2 switch や L2 host は、イーサネットフレームである
#    Nwdiy::Packet::Ethernet を処理するので、Nwdiy::XXX::Ethernet
#    の機能を含んでいます。
#
#    この機能モジュールをインクルードしたクラスのインスタンスは、
#    パケットのフィールド名とその値あるいは別名を指定することで
#    梱包されたデータの中身を処理するクラスを設定できます。
#
#  例1
#    +----------+      +------+
#    | etherip  | ---- | eth3 |
#    +----------+      +------+
#    |   ipv4   |
#    +----------+
#    |   eth2   |
#    +----------+
#
#
#  例2
#    +---------+                                  +--------+
#    |  httpA  |                                  |  httpB |
#    +---------+    +------------------------+    +--------+
#    |  tcpA   |    |         router         |    |  tcpB  |
#    +---------+    +------+-+------+-+------+    +--------+
#    |  ipv4A  | -- | ipv4 | | ipv4 | | ipv4 | -- |  ipv4B |
#    +---------+    +------+ +------+ +------+    +--------+
#                            | eth1 |
#                            +------+
#
#  例3
#    +--------+ +--------+
#    |  http  | |  http  |
#    +--------+ +--------+
#    |  tcp   | |  tcp   |
#    +--------+ +--------+    +------+-+------+
#    |        | |  ipv4  | -- | ipv4 | |      |
#    |        | +--------+    +------+ |      |
#    |        |                        |      |
#    |  ipv4  | ---------------------- | ipv4 |
#    +--------+                        +------+







#
#    os.eth1 | fw1 | eth2
#    eth2.ipv4.etherip = EtherIPBalancer.new
#    eth2.ipv4.etherip[1].local = "192.0.2.11"
#    eth2.ipv4.etherip[1].peer  = 

#    その内容が 172.0.2.2 から 172.0.2.1 への EtherIP であれば、
#    そのデータ (イーサネットフレーム) を eth1.vlan[0] に渡します。
#    これを受けた eth1.vlan[0] は、VLAN id 10 を添付して、
#    eth1 から


# インスタンスは OS のインターフェース "eth0" で
#    受信したイーサネットフレームの
#    受信したフレームのうち宛先 00:00:0e:00:00:01 での IPv4 パケットは
#    work1.ipv4 インスタンスに渡します。
#
#    たとえばイーサネットフレームを処理するクラスのインスタンスとして
#    work1 があるとき、これに対するメソッド work1.ipv4 は
#    IPv4 パケットを処理するインスタンスを生成します。
#    work1 で受信したイーサネットフレームのうちの IPv4 パケットは、
#    work1.ipv4 インスタンスに上げられてそこで受信します。
#    work1.ipv4 インスタンスにローカルアドレスなど設定しておくことで
#    work1.ipv4 インスタンスで受信する IPv4 パケットを絞り込むことも
#    できます。
#
#    あるいは逆方向に、
#    work1.ipv4 インスタンスで受信した IPv4 パケットのうち TCP の
#    ストリームデータは work1.ipv4.tcp インスタンスがあれば
#    そこで受信します。
#    work1.ipv4.tcp インスタンスにローカルポート番号など設定しておくことで
#    work1.ipv4.tcp インスタンスで受信する TCP ストリームデータを
#    絞り込むこともできます。
#    work1.ipv4 は、ローカルポート番号の異なる複数の TCP インスタンスを
#    持つことができます。XXX どう表現する？ XXX
#
# Nwdiy::Net
#
#    Nwdiy::Work を結び、Nwdiy::Packet を受け渡します。
#
#
# モジュール変数には以下があります。
# - VERSION
#
################################################################

require "spec_helper"

RSpec.describe Nwdiy do
  it "has a version number" do
    expect(Nwdiy::VERSION).not_to be nil
  end

  # it "has some MACRO in Linux /usr/include/" do
  #   expect(Nwdiy::SOL_PACKET).not_to be nil
  #   expect(Nwdiy::ETH_P_ALL).not_to be nil
  #   expect(Nwdiy::PACKET_ADD_MEMBERSHIP).not_to be nil
  #   expect(Nwdiy::PACKET_DROP_MEMBERSHIP).not_to be nil
  #   expect(Nwdiy::PACKET_MR_PROMISC).not_to be nil
  #   expect(Nwdiy::etc("7/tcp")).to eq("echo")
  # end
end

# RSpec.describe String do
#   it "has btoh function" do
#     expect("\x00".btoh).to eq(0)
#     expect("\x00\x01".btoh).to eq(1)
#     expect("\x00\x01\x02".btoh).to eq(0x0102)
#     expect("\x00\x01\x02\x03".btoh).to eq(0x010203)
#     expect("\x00\x01\x02\x03\x04".btoh).to eq(0x01020304)
#   end
# end

# RSpec.describe Integer do
#   it "has htob function" do
#     expect(0x01.htob32).to eq("\x00\x00\x00\x01")
#     expect(0x01.htob16).to eq("\x00\x01")
#     expect(0x01.htob8).to eq("\x01")
#   end
#   it "has htonl, htons" do
#     expect(0x01.htonl).to eq(0x01000000)
#     expect(0x80000000.htonl).to eq(0x80)
#     expect(0x01.htons).to eq(0x0100)
#     expect(0x8000.htons).to eq(0x80)
#   end
# end
