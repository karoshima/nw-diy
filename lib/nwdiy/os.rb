#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# ruby で綴る、OS チェッカー
# NwDiy::OS.linux?   Linux なら真を返す
# NwDiy::OS.win?     Windows なら真を返す

require_relative '../nwdiy'
require 'rbconfig'

module NwDiy::OS
  private
  def self.os
    os = RbConfig::CONFIG['host_os']
    case os
    when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
      :windows
    when /linux/
      :linux
    else
      raise Error "unknown OS: #{os}"
    end
  end

  public
  def self.linux?
    os == :linux
  end
  def self.win?
    os == :win
  end
end
