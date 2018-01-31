#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

class Nwdiy::Func::Ifp::OS < Nwdiy::Func::Ifp

  include Nwdiy::Debug
  #  debugging true

  # 初期化
  def initialize(name = nil)
    super
    @link = Hash.new
  end
  @@name_seed = 0
  def class_name
    "os"
  end

  # インターフェースを作る
  def eth(name = nil)
    return @link[name] if name && @link[name]
    newlink = Nwdiy::Func::Ifp::Ethernet.new(name)
    return @link[newlink.to_s] = newlink
  end
  def real_eth(name)
    return @link[name] if name && @link[name]
    return @link[name] = Nwdiy::Func::Ifp::Ethernet.new(name, real: true)
  end

  # OS そのものはパケットのためのものではないので、
  # 送受信系の機能は無効にする。
  undef ready? if defined? ready?
  undef recv if defined? recv
  undef send if defined? send
  undef attach if defined? attach
  undef attach_left if defined? attach_left
  undef attach_right if defined? attach_right
  undef detach if defined? detach
  undef |
end
