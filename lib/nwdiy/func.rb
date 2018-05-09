#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2018 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# with Apache-2 license.  check /LICENSE please.
################################################################
# top of NW-DIY functions.
################################################################

module Nwdiy
  module Func

    autoload(:PktQueue,         'nwdiy/func/pktq')
    autoload(:Ethernet,         'nwdiy/func/ethernet')
    autoload(:EthernetReceiver, 'nwdiy/func/ethernet')

    MAXQLEN = 16

    attr_accessor :to_s

    private
    def initialize(name)
      @to_s = name
    end

  end
end
