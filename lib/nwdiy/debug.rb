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
      self.class.debug_msg(*msg)
    end
  end

  module ClassMethods

    def debug(*msg)
      debug_msg(msg)
    end

    def debug_on(*msg)
      caller(1)[1] =~ %r{(lib/nwdiy/.*)$}
      tm = Time.now.strftime "%T.%6N"
      puts "#{tm}: #{$1}: " + msg.join(", ")
    end
    def debug_off(*msg)
    end
    
    def debugging(flag = true)
      if flag
        alias :debug_msg :debug_on
      else
        alias :debug_msg :debug_off
      end
    end
    alias :debug_msg :debug_off
  end

end
