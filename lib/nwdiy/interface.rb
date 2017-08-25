#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# Nwdiy::Interface は Nwdiy::Interface::XXX の親モジュールです。
# ここでは Nwdiy::Interface::XXX が持つメソッドについて
# ソースコード内に解説してあります。
################################################################

require 'nwdiy'

module Nwdiy::Interface

  autoload(:Ethernet,  'nwdiy/interface/ethernet')

  ################
  # Nwdiy::Interface::XXX に必要なメソッド

  ################
  # def initialize    インスタンスを生成します

  ################
  # 送受信
  #
  # self | other
  #    このインターフェースで受信したパケットを
  #    other インスタンスの左側から右に向けて流し続けます。
  #    また、other から左向きに出てきたパケットを外部に送信します。
  #
  # other | self
  #    other から右向きに出てきたパケットを外部に送信します。
  #    また、このインターフェースで受信したパケットを
  #    other インスタンスの右側から左に向けて流し続けます。
  #
  # ready?
  #    このインターフェースにパケットが届いていれば true を返します。
  #    届いていなければ false を返します。
  #
  # recv
  #    届いたパケット (Nwdiy::Packet::XXX) を返します。
  #    パケットが届いていなければ、届くまでブロックします。
  #
  # send(pkt)
  #    パケット (Nwdiy::Packet::XXX あるいは String) を送信します。
  #
  ################################################################

end
