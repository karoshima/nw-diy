#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require "io/wait"

class Nwdiy::Func::Out < Nwdiy::Func

  autoload(:Ethernet, 'nwdiy/func/out/ethernet')
  autoload(:Pipe,     'nwdiy/func/out/pipe')

end
