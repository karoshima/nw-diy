#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require "spec_helper"

RSpec.describe Nwdiy::Packet do
  it "calculate checksum" do
    data = ["\0\0\0\0\0\0\0\0", "\0\0\0\0\0\0\0\0"]
    expect(Nwdiy::Packet.calc_cksum(*data)).to be(0xffff)
  end
end
