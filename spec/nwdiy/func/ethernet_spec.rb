#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require "pp"

require "spec_helper"
require "socket"
require "rbconfig"

RSpec.describe Nwdiy::Interface::Ethernet do
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
      eth1 = Nwdiy::Interface::Ethernet.new(ifp)
      expect(eth1).not_to be nil
      expect(eth1.addr.unicast?).to be true
      expect(eth1.addr.multicast?).to be false
      expect(eth1.addr.broadcast?).to be false
      if ifp == "nwdiy0"
        expect(eth1.addr.global?).to be false
        expect(eth1.addr.local?).to be true
      else
        #下記はroot権限を取得できるか否かで結果が変わるので省略
        #expect(eth1.addr.global?).to be true
        #expect(eth1.addr.local?).to be false
      end
      eth2 = Nwdiy::Interface::Ethernet.new(ifp)
      expect(eth2).not_to be nil
      expect(eth2.addr.unicast?).to be true
      expect(eth2.addr.multicast?).to be false
      expect(eth2.addr.broadcast?).to be false
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
