#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# インターフェース機能の抽象クラスです。
# パケットを開き、データ種別ごとに分別して上流に流します。
# また、上流から送出されるパケットを適切に梱包します。
#
# たとえばこんなことをやります。
# - OS のイーサネットデバイスからイーサネットフレームを受信する。
# - イーサネットフレームを OS のイーサネットデバイスから出す。
# - イーサネットデバイスの IPv4 インターフェースから IPv4 パケットを受信する。
# - IPv4 パケットをイーサネットフレームで包んでイーサネットデバイスから出す。
# - IPv4 インターフェースの TCP インターフェースから TCP パケットを受信する
# - TCP パケットを IPv4 パケットで包んで IPv4 インターフェースから出す。
# - OS の TCP ポートからデータを受信する。
# - データを TCP で包んで OS から出す。
#
# 実際には Nwdiy::Func::Ifpq の子クラスとして
# イーサネットインターフェース, IPv4 インターフェースなどがあり
# それらを new して利用するようになっています。
# また定数として Nwdiy::OS をひとつ持っています。
#
#【特異メソッド】
#
# new(name) -> Nwdiy::Func::Ifp
#    インターフェースを生成します。
#
#【インスタンスメソッド】
#
# on -> bool
# off -> bool
#    インターフェースの稼動状態を設定して、その結果を返します。
#
# power -> bool
#    インターフェースの稼動状態を返します。
#
# ready? -> bool
#    パケットが届いているか、すぐに返せるかどうかを返します。
#
# recv -> Nwdiy::Packet
#    パケットがひとつ届くまで待ち、
#    届いたパケットを返します。
#
# send(pkt) -> Integer
#    パケットを送信します。
#    パケットサイズを返します。
#
# sent -> Integer
#    送信したパケットの数を返します。
#
# received -> Integer
#    受信したパケットの数を返します。
#
# local -> Nwdiy::Packet
#    インスタンスのローカルアドレスを返します。
#    イーサネットインターフェースなら自分の MAC アドレスを返します。
#    IPv4 インターフェースなら自分の IPv4 アドレス/マスクを返します。
#
# local = address -> address
#    インスタンスのローカルアドレスを設定します。
#    イーサネットインターフェースなら自分の MAC アドレスを設定します。
#    IPv4 インターフェースなら自分の IPv4 アドレス/マスクを設定します。
#
#【子クラスのインスタンスメソッド】
#
# xxx -> Nwdiy::Func::Ifp
#    本インスタンスから取り出す子インスタンスを返す。
#    存在しなければ自動的に生成する
#    たとえば ethernet_ifp.ipv4 は IPv4 インターフェースを返します。
#    また ipv4_ifp.udp は UDP インターフェースを返します。
#
# xxx = ifp
#    本インスタンスから取り出す子インスタンスを設定します。
#
################################################################
