#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require "nwdiy"

class Nwdiy::Func

  include Nwdiy::Debug
  #  debugging true

  autoload(:Out, 'nwdiy/func/out')

  @power; attr_accessor :power
  def on
    @power = true
  end
  def off
    @power = false
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

  def |(other)
    debug "#{self}(#{self.class}) | #{other}(#{other.class})"
    raise "This is not Nwdiy::Packet: '#{other}'" unless
      other.kind_of?(Nwdiy::Func)
    if self.kind_of?(Nwdiy::Func::Out)
      other.attach_left(self)
    elsif other.kind_of?(Nwdiy::Func::Out)
      self.attach_right(other)
    else
      p1, p2 = Nwdiy::Func::Out.pair.each {|p| p.on }
      
      self.attach_right(p1)
      other.attach_left(p2)
    end
    other
  end
end
