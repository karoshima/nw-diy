#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# 本プログラムは Linux 上で root 権限で動かしておくと、
# 一般ユーザー権限で動く NW-DIY で物理インターフェースからの送受信を
# 代理で行ないます
################################################################

require "bundler/setup"
require "nwdiy"

begin
  Nwdiy::Func::Ethernet::ProxyDaemon.new.run
rescue Interrupt
end
