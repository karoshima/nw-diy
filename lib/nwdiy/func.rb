#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# Nwdiy::Func は Nwdiy::Func::XXX の親モジュールです。
# ここでは Nwdiy::Packet::XXX が持つメソッドについて
# ソースコード内に解説してあります。
#
# また、各種 Func 共通で使用する機能について定義しています。
################################################################

require "nwdiy"

module Nwdiy::Func

  autoload(:Ethernet, "nwdiy/func/ethernet")

  ################################################################
  # Nwdiy::Func::XXX に必要なメソッド

  ################
  # def initialize              インスタンスを生成します

  ################
  # パケットの送受信
  #
  # def ready?
  #    このインスタンスで処理したパケットがあれば true を返します。
  #
  # def read(option = {})
  #    このインスタンスで処理したパケット (Nwdiy::Packet::XXX) を返します。
  #    パケットが届いていなければ、届くまで待ちます。
  #
  #    以下のオプションを使用できます。
  #      :promisc       true であれば、自分宛でなくても返します。
  #                     このとき一緒に PKTTYPE_XXX を返します。
  #
  # def send(pkt)
  #    このインスタンスからパケット (Nwdiy::Packet あるいは String) を
  #    送信します。
  #
  # def |(func)
  #    このインスタンスで処理したパケットを次のインスタンス func に
  #    渡し続けます。
  #    また func から送信されたパケットをこのインスタンスで処理して
  #    送信し続けます。
  #
  # 受信パケット種別
  PKTTYPE_HOST      = 1    # 自分宛パケット
  PKTTYPE_BROADCAST = 2    # 物理層ブロードキャストパケット
  PKTTYPE_MULTICAST = 3    # 物理層マルチキャストパケット
  PKTTYPE_OTHERHOST = 4    # 他人宛パケット
  PKTTYPE_OUTGOING  = 5    # 自分が出したパケット
  ################

end
