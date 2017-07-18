#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

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
      expect(eth1.send("Hello world")).not_to be nil
      sleep 0.1
      pkt = Array.new
      while eth2.ready?
        pkt << eth2.recv
      end
      expect(pkt.include?("Hello world")).to be true
    end
  end
end
