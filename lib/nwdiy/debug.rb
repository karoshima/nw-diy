#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require "nwdiy"

module Nwdiy::Debug
  @@debug = Hash.new
  def debug(msg)
    caller(1)[0] =~ %r{(lib/nwdiy/.*)$}
    puts "#{$1}: " + msg if @@debug[self.class]
  end
  def debugging(flag = true)
    @@debug[self.class] = flag
  end
end
