#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require "nwdiy"

class Nwdiy::Func
  def on
    false
  end
  def off
    false
  end
  def power
    false
  end
  def attach_left(pipe)
    raise NotImplementedError.new("attach_left must be overwritten")
  end
  def attach_right(pipe)
    raise NotImplementedError.new("attach_left must be overwritten")
  end
  def detach(pipe)
    raise NotImplementedError.new("attach_left must be overwritten")
  end
end
