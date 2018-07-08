#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

module Nwdiy::Debug

  def self.included(cls)
    cls.include Nwdiy::Debug::Methods
    cls.extend  Nwdiy::Debug::Methods
  end

  module Methods
    def debug(*msg)
      return unless $VERBOSE
      caller(1)[0] =~ %r{(lib/nwdiy/.*)$}
      tm = Time.now.strftime "%T.%6N"
      puts "#{tm}: #{$1} in #{self}: " + msg.join(", ")
    end
  end

end
