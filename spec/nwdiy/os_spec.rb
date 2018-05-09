#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2018 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# with Apache-2 license.  check /LICENSE please.
################################################################
# OS functions.
#
# Nwdiy::OS create at the beginning of nwdiy script.
# This is static variable.
# 
# This has a method "ether", which act as the Ethernet of its own.
################################################################

require "spec_helper"

RSpec.describe Nwdiy::OS do
  
  # return the Nwdiy::Func::Ethenret instance if you have the permission
  # to open PF_PACKET or to connect pfpkt_server.
  # otherwise,  raise Errno::EPERM.
  it "can create an Ethernet device" do
    begin
      ifindex, ifp = Nwdiy::OS::Pfpkt.__send__(:init_pfpkt, "lo")
    rescue Errno::EPERM
      skip "you have no permission to test PF_PACKET"
    end
    expect(ifp).to be_a Socket
    ifp.close
    expect(Nwdiy::OS.ethernet('lo')).to be_a(Nwdiy::Func::Ethernet)
  end
end
