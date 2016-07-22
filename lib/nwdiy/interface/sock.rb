#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# ruby で綴る、AF_UNIX による VM interface

require_relative '../../nwdiy'

module NwDiy
  class Interface
    class Sock
      include NwDiy::Linux

      def initialize(name)
      end

    end
  end
end
