#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require "pp"

require "spec_helper"
require "socket"
require "rbconfig"

RSpec.describe Nwdiy::Func::Ethernet do
  iflist = ["nwdiy0"]
  if RbConfig::CONFIG["host_os"] =~ /linux/
    ifs = Socket.getifaddrs
    ifs.select! do |ifp|
      (ifp.flags & Socket::IFF_UP) != 0 &&
      (ifp.flags & Socket::IFF_RUNNING) != 0
    end
    iflist << ifs.sample.name
  end

  iflist.each do |ifp|
    it "creates Ethernet #{ifp}" do
      eth1 = Nwdiy::Func::Ethernet.new(ifp)
      expect(eth1).not_to be nil
      eth2 = Nwdiy::Func::Ethernet.new(ifp)
      expect(eth2).not_to be nil
      spkt = Nwdiy::Packet::Ethernet.new
      spkt.dst = "00:00:00:00:00:01"
      spkt.src = "00:00:00:00:00:02"
      spkt.type = 0x0800
      spkt.data = "Hello World"
      expect(eth1.send(spkt)).not_to be nil
      sleep 0.1
      rpkt = Array.new
      while eth2.ready?
        rpkt << eth2.recv
      end
      expect(rpkt.include?(spkt)).to be true
    end
  end
end
