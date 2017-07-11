#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'nwdiy'

################################################################
# イーサネットケーブル
# Nwdiy::Cable::Ethernet
################
# 作成
eth00 = Nwdiy::Cable::Ethernet.new("eth00")
################
# パケット送受信
#    pkt のクラスは Nwdiy::Packet::Ethernet.new
pkt = Nwdiy::Packet::Ethernet.new
pkt.xxx = yyy
eth00.send(pkt)
pkt = eth00.recv

################################################################
# VLAN ケーブル
# Nwdiy::Cable::VLAN < Nwdiy::Cable::Ethernet
################
# 作成
#    ケーブルから vlan-id 指定で分岐させてもよい
#    また vlan-id 指定でケーブルにくっ付けてもよい
#    (VLAN 自体もまたケーブルなので、多段にできる)
vlan01 = Nwdiy::Cable::VLAN.new
vlan01 = eth00.vlan[1]
eth00.vlan[1] = vlan01
################
# パケット送受信
#    pkt のクラスは Nwdiy::Packet::Ethernet.new
#    送信すると pkt に VLAN ヘッダを付与したのち実際に送信する
#    受信したパケットのうち vlan-id の一致するものだけを返す
vlan01.send(pkt)
pkt = vlan01.recv

################################################################
# QinQ ケーブル
# Nwdiy::Cable::QinQ < Nwdiy::Cable::VLAN
################
# VLAN とは EtherType が違うだけ
################

################################################################
# イーサホスト
# Nwdiy::Node::Ethernet
################
# 作成
#    ケーブルからアドレス指定で分岐させる
#    アドレス指定でケーブルにくっ付けてもよい
#    アドレスの代わりに名前を指定してもよい (アドレスは自動割り当て)
l2h = Nwdiy::Node::Ethernet.new
l2h = eth00.mac["00:00:0e:00:00:03"]
eth00.mac["00:00:0e:00:00:03"] = l2h
l2h = eth00.name["host03"]
eth00.name["host03"] = l2h
################
# パケット送受信
#    pkt のクラスは Nwdiy::Packet::Ethernet.new
#    送信すると pkt の送信元アドレスは自アドレスになる
#    受信したパケットのうち宛先が自アドレスのものやブロードキャストなどを返す
l2h.send(pkt)
pkt, type = l2h.recv
#    type = Nwdiy::Host.PACKET_HOST      自分宛パケット
#    type = Nwdiy::Host.PACKET_BROADCAST ブロードキャストパケット
#    type = Nwdiy::Host.PACKET_MULTICAST マルチキャストパケット

################################################################
# イーサスイッチ
# Nwdiy::Node::Ethernet (同上) < Hash
################
# 作成
#    使いたいケーブルに、アドレスあるいは名前指定でくっ付ける
l2h = Nwdiy::Node::Ethernet.new
eth01.addr["00:00:0e:00:04:01"] = l2h
eth02.name["eth02-l2h"] = l2h
vlan03.addr["00:00:0e:00:04:03"] = l2h
#    あるいは使いたいケーブルを追加する (アドレスは手動割り当て)
l2h["00:00:0e:00:04:04"] = eth04
#    あるいは使いたいケーブルを追加する (アドレスは自動割り当て)
l2h["eth02-l2h"] = eth05
l2h << eth06 << vlan07
#    イーサスイッチを追加すると、追加されたやつは追加先に吸収される (スタック)
l2h << l2h02 << l2h03
################
# 繋がってるケーブル
l2h["00:00:0e:00:04:03"]
################
# 自分が持ってるアドレスの一覧
l2h.keys
################
# 電源操作
l2h.swon  # 電源オン
l2h.swoff # 電源オフ
################
# 学習テーブルの登録・削除と閲覧
#    登録されているエントリーは NwDiy::Route::MAC
#    転送先インターフェース以外は代入可能
route = Nwdiy::Route::MAC
l2h.rt[route.dest] = dest
l2h.rt.delete(route.dest)
l2h.rt.delete(route)
転送先 = l2h.rt["00:00:0e:00:00:03"].ifp

################################################################
# IPv4ホスト
# Nwdiy::Node::IPv4 < Hash
################
# 作成
#    イーサホストからアドレス指定で分岐させる
#    アドレス指定でイーサホストにくっ付けてもよい
l3h = NwDiy::Node::IPv4.new
l3h = l2h.ipv4["192.0.2.4/24"]
l2h.ipv4["192.2.0.4/24"] = l3h
################
# イーサホストの参照と書き換え
l2h = l3h["192.2.0.4/24"]
l3h["192.2.0.4/24"] = l2h
################
# パケット送受信
#    pkt のクラスは Nwdiy::Packet::IPv4.new
#    送信すると
#    - pkt の送信元アドレスは自 IPv4 アドレスに書き換えられる
#    - pkt がイーサホストから出るときは、ARP 解決できてから出る
#    受信したパケットのうち宛先が自アドレスのものなどを返す
l3h.send(pkt)
pkt, l2type, l3type = l3h.recv
#    l2type, l3type = NwDiy::Host.PACKET_(同上)

################################################################
# IPv4スイッチ
# Nwdiy::Node::IPv4 (同上) < Hash
################
# 作成
#    使いたいイーサホストに、アドレス指定でくっ付ける
l3h = NwDiy::Node::IPv4.new
l2h01.ipv4["192.0.2.4/24"] = l3h
l2h02.ipv4["192.51.100.4/24"] = l3h
#    あるいは使いたいイーサホストを追加する
l3h["192.0.2.4/24"] = l2h01
################
# 繋がってるイーサホスト
l3h["192.0.2.4/24"]
################
# 自分が持ってるアドレスの一覧
l3h.keys
################
# 電源操作
l3sw.swon   # スイッチオン
l3sw.swoff  # スイッチオフ
################
# ルーティングテーブルの登録・削除と参照
#    登録されているエントリーは Nwdiy::Route::IPv4
#    参照できる
route = Nwdiy::Route::IPv4
l3h.rt[route.dest] << route
l3h.rt.delete(route)
転送先 = l3h.rt["203.0.113.5"][0].ifp
転送先リスト(優先度の高い順) = l3h.rt["203.0.113.5"]

################################################################
# IPv6ホスト, IPv6スイッチ
# 同上

################################################################
# UDP
# Nwdiy::Node::UDP
################
# 作成
#    使いたい IPv4/IPv6 ホストに、ポート番号指定でくっ付ける
udp = Nwdiy::Node::UDP.new
l3h.udp[4789] = udp

################################################################
# VXLAN スイッチ
# Nwdiy::Node::VXLAN
################
# 作成
#    使いたい IPv4/IPv6 ホストにくっ付ける
vxlan = Nwdiy::Node::VXLAN.new
l3h.vxlan["192.0.2.4"] = vxlan  # アドレス固定の場合
l3h.vxlan["::"] = vxlan         # どのアドレスでもいい場合 ("0.0.0.0" とか)
#    イーサネットケーブルの取り出し、設定
eth10 = vxlan.vni(10)
vxlan.vni(11) = Nwdiy::IFP::Ethernet.new("eth11")
#    BUM 除けのおまじない
#      VNI 番号 と MACアドレスをキーに、転送先 VXLAN VTEP を指定する
vxlan.rt[10, "00:00:0e:00:00:07"] = "192.0.2.7"
#      IPv4/IPv6 アドレスをキーに、ARP/NDP で返す MAC アドレスを指定する
vxlan.rt[11, "2001:db8::11"] = "00:00:0e:00:00:07"
#      エントリー削除
vxlan.rt.delete(vni, key)
