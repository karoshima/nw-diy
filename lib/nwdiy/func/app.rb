#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require "nwdiy"

class Nwdiy::Func::App < Nwdiy::Func
  
  include Nwdiy::Debug
  debugging = true

  @out
  @name
  attr_reader :name
  alias :to_s :name

  def attach(out)
    raise Error.new "#{self} has already connected to #{@out}" if @out
    @out = out
    self
  end
  alias :attach_left :attach
  alias :attach_right :attach

  def attached
    [@out]
  end
  def detach(out = @out)
    raise Error.new "#{self} has no connection" unless @out
    raise Error.new "#{self} is not connected to #{out}" unless out == @out
    @out = nil
    out
  end

  class Error < Exception
  end
end
