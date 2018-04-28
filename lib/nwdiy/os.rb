#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2018 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# with Apache-2 license.  check /LICENSE please.
################################################################

class Nwdiy::OS

  class << self

    public
    def ether(name)
      return Nwdiy::Func::Ethernet.new(name)
    end
  end
end
