#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require "spec_helper"

RSpec.describe Nwdiy::Func do
  it "has receiving packet types" do
    expect(Nwdiy::Func::PKTTYPE_HOST).not_to be nil
    expect(Nwdiy::Func::PKTTYPE_BROADCAST).not_to be nil
    expect(Nwdiy::Func::PKTTYPE_MULTICAST).not_to be nil
    expect(Nwdiy::Func::PKTTYPE_OTHERHOST).not_to be nil
  end
end
