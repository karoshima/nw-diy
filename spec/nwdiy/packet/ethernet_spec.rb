#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require "spec_helper"

RSpec.describe Nwdiy::Packet::Ethernet do
  it "creates empty ethernet packet" do
    pkt = Nwdiy::Packet::Ethernet.new
    expect(pkt.dst).to eq("00:00:00:00:00:00")
    expect(pkt.data).to eq("")
  end
end
