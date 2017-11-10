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

require "optparse"
require "nwdiy"

if $0 == __FILE__

  opt = OptionParser.new
  opt.on("-w") do |val|
    $VERBOSE = true
  end
  opt.parse!(ARGV)

  begin
    Nwdiy::Func::Out::Ethernet.start_server.join
  rescue Interrupt
  end
end
