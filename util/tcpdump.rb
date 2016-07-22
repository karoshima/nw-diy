#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# ruby で綴る VM interface のための、tcpdump

require_relative '../lib/nwdiy'

require 'nwdiy/interface'

ifp = NwDiy::Interface.new(ARGV[0])
loop do
  puts ifp.recv
end
