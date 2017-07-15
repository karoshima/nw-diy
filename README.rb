#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'nwdiy'

################################################################
# たとえば
################################################################
# パケットの送受信
eth0 = Nwdiy::Func::Ethernet.new "eth0"
pkt = eth1.vlan[1].ip["192.0.2.1/24"].vxlan[1].recv
eth2.vlan[2].ip["192.0.2.2/24"].vxlan[2].send(pkt)
################
# フィルター
filter = Nwdiy::Func::Filter.new
filter.xxx = yyy # もろもろ設定
eth0 | filter | eth1
################
# 外に出るパケットには source NAT をかける
#    NW-DIY は双方向のパケットの流れを扱うので
#    eth2 に戻ってきたパケットへの NAT 戻しも行なう
nat = Nwdiy::Func::Nat.new
nat.xxx = yyy # もろもろ設定
eth0 | nat | eth2
################
# L2ブリッジ
#    bridge インスタンスに入ったパケットは
#    bridge インスタンスに繋がったどれかのインターフェースから送信する
#    bridge インスタンスにインターフェースを繋げるときは、右でも左でもよい
#    NW-DIY はいずれにせよ双方向のパケットの流れを扱う
bridge = Nwdiy::Func::Bridge.new
eth0 | bridge
eth1 | bridge | eth2
eth3.vlan[3] | bridge
eth4.vlan[4].ip["192.0.2.4/24"].vxlan[4] | bridge
################
# IPv4ルーティング
# (route インスタンスに入ったパケットは
#  そのインスタンスに繋がったどれかのインターフェースから送信)
route = Nwdiy::Func::Routing4.new
eth1.ip["192.0.2.1/24"] | route
eth2.vlan[2].ip["198.51.100.2/24"] | route
################
# IPv6ルーティング
# (ほぼ同上)
route = NwDiy::Func::Routing6.new
eth1.ip["2001:db8:0:1::1/64"] | route
eth2.ip["192.0.2.2/24"].vxlan[2].ip["2001:db8:0:2::2/64"] | route
# 長いから分けよう
eth3 = eth1.ip["192.0.2.1/24"].vxlan[3]
eth3.ip["2001:db8:0:3::3/64"] | route
################
# L2 & L3
# eth1 や eth2 で受信したパケットは、
# 自 MAC 宛じゃなければ bridge インスタンスで eth1, eth2 に
bridge = Nwdiy::Func::Bridge.new
route = NwDiy::Func::Routing4.new
eth1 | bridge.ip["192.0.2.1/24"] | route
eth2 | bridge

################################################################
# 詳細
################################################################

################################################################
# イーサネット
# Nwdiy::Func::Ethernet
################
# 作成
eth0 = Nwdiy::Func::Ethernet.new("eth0")
################
# パケット送信
#    pkt は Nwdiy::Packet::Ethernet のインスタンス
#    pkt は OS (Linux) のインターフェースあるいは疑似インターフェースから
#    外に送信される
eth0.send(pkt)
################
# パケット受信
#    OS (Linux) のインターフェースあるいは疑似インターフェースに届いた
#    自分宛やブロードキャストなどのパケットを受信して返す。
#    届いてなければ、届くまでブロックされる。
pkt = eth0.recv
################
# パケット送受信
#    func は Nwdiy::Func:XXX (何らかのネットワーク機能) のインスタンス
#    eth0 で受信したパケットは func で往路処理をして eth1 に送信する
#    eth1 に戻ってきたパケットは func で復路処理をして eth0 に送信する
eth0 | func | eth1
################
# MAC アドレスの参照, 設定
eth0.addr
eth0.addr = "00:00:0e:00:00:01"

################################################################
# VLAN
# Nwdiy::Func::VLAN
################
# 作成
#    イーサネットから vlan-id 指定で分岐させて作る
vlan1 = eth1.vlan[1]
################
# パケット送信
#    パケットに VLAN タグを付けて eth1 から送信される。
eth1.vlan[1].send(pkt)
################
# パケット受信
#    eth1 で vlan id 1 のパケットを受信し、VLAN タグを外して返す。
pkt = eth1.vlan[1].recv
################
# MAC アドレスはイーサネットのものを流用する
# VLAN ごとに上書き可能
vlan1.addr = "00:00:0e:00:00:02"

################################################################
# QinQ
# Nwdiy::Func::QinQ
################
# VLAN とは EtherType が違うだけ
################

################################################################
# L2ブリッジ
# Nwdiy::Func::Bridge
################
# 作成
bridge = Nwdiy::Func::Bridge.new
################
# パケット中継
#    bridge にパケットを流し込んでくるイーサネット間でブリッジ処理を行なう
eth0 | bridge
eth1 | bridge
eth2 | bridge
################
# パケット中継
#    bridge の入口にあたるイーサネットフレームも
#    bridge の出口にあたるイーサネットフレームも
#    立場に違いはない (下記の eth0-eth3 は全く同等の扱いを受ける)
eth0 | bridge | eth1
eth2 | bridge | eth3
################
# 作成
#    最初からブリッジ処理対象となるイーサネットを指定してもよい
bridge = Nwdiy::Func::Bridge.new(eth0, eth1, vlan2, vlan3)
################
# パケット中継
bridge.start
################
# イーサネット一覧
bridge[]
################
# 学習テーブル参照
bridge.table
################
# パケット送信
#    bridge のどれかあるいは全てのインターフェースから送信される
bridge.send(pkt)
################
# パケット受信
#    自 MAC 宛やブロードキャストパケットなどを受信する
pkt = bridge.recv
################
# パケット受信
#    bridge で中継されている全てのパケットを受信する
pkt = bridge.recv({:promisc = true})

################################################################
# IPv4 ホスト
# Nwdiy::Func::IPv4
################
# 作成
#    イーサネットなどのネット機能から IP アドレス指定で分岐させる
inet1 = eth1.ip["192.0.2.1/24"]
inet1 = eth1.vlan[1].ip["192.0.2.1/24"]
inet1 = bridge.ip["192.0.2.1/24"]
################
# パケット送受信
#    pkt は Nwdiy::Packet::IPv4 のインスタンス
inet1.send(pkt)
pkt = inet1.recv

################################################################
# IPv4 ルーティング
# Nwdiy::Func::Routing4
################
# 作成
route1 = Nwdiy::Func::Routing4.new
################
# パケット中継
#    route にパケットを流し込んでくるネット間で
#    ルーティング処理を行なう
inet1 | route
inet2 | route
inet3 | route
################
# パケット中継
#    route の入口にあたるイーサネットフレームも
#    route の出口にあたるイーサネットフレームも
#    立場に違いはない (下記の inet1-inet4 は全く同等の扱いを受ける)
inet1 | route | inet2
inet3 | route | inet4
################
# パケット中継
#    bridge と route の併用
eth1 | bridge1 | eth2
eth3 | bridge3 | eth4
bridge1.ip["192.0.2.1/24"] | route | bridge2.ip["198.51.100.2/24"]
################
# 作成
#    最初からルーティング処理対象となるホスト群を指定してもよい
route = Nwdiy::Func::Routing4.new(inet1, inet2, bridge2)
################
# IPv4 インターフェース一覧
route[]
################
# ルーティングテーブル参照
route.table

################################################################
# IPv6 ホスト
# Nwdiy::Func::IPv6
################################################################
# IPv6 ルーティング
# Nwdiy::Func::Routing6
################
# 基本的に IPv4 ルーティングと同じ使いかたになる
# 設定パラメーターなどは IPv6 アドレスになる

################################################################
# VXLAN
# Nwdiy::Func::VXLAN
################
# 作成
#    IPv4 あるいは IPv6 ホストから VTEP 指定で分岐させて作る
vxlan1 = inet4.vxlan[1]
################
# 作成
#    VXLAN 自体もまたイーサネットなので、多段にできる
vlan11 = inet4.vxlan[1].ip["192.0.2.1/24"].vxlan[2]
