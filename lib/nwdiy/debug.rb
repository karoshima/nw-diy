#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require "nwdiy"

module Nwdiy::Debug

  def self.included(cls)
    cls.include Nwdiy::Debug::InstanceMethods
    cls.extend  Nwdiy::Debug::ClassMethods
  end

  module InstanceMethods
    # インスタンスメソッドの debug() は
    # クラスメソッドの debug() に処理をまわす
    def debug(*msg)
      self.class.debug(*msg)
    end
  end

  module ClassMethods
    def debug_on(*msg)
      caller(1)[0] =~ %r{(lib/nwdiy/.*)$}
      puts "#{$1}: " + msg.join(", ")
    end
    def debug_off(*msg)
    end

    alias :debug :debug_on
    def debugging(flag = true)
      if flag
        alias :debug :debug_on
      else
        alias :debug :debug_off
      end
    end
  end

end
