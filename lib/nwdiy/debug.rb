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

  # なんで include Nwdiy::Debug しても
  # ここで def self.debugging したのが効かないんだろう？
  # 仕方ないので引数にクラスを入れて誤魔化す

  def self.set(cls, flag = true)
    @@debug[cls] = flag
    p self
  end
  def self.msg(cls, msg)
    return unless @@debug[cls]
    caller(1)[0] =~ %r{(lib/nwdiy/.*)$}
    puts "#{$1}: " + msg
  end
end
