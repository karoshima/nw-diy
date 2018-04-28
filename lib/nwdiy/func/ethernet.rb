#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2018 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# with Apache-2 license.  check /LICENSE please.
################################################################
# Ethernet interface

module Nwdiy
  module Func
    class Ethernet
      def initialize(name)
        @to_s = name
      end
      attr_accessor :to_s
    end
  end
end
