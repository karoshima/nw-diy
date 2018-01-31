#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# イーサネットフレームを送受信するネットワーク機能です。
#
################################################################

require "spec_helper"

RSpec.describe Nwdiy::Func::Ifp::Ethernet do
  it "has class methods" do
    expect(Nwdiy::Func::Ifp::Ethernet.respond_to?(:new)).to be true
  end

  it "has instance methods" do
    hoge = Nwdiy::Func::Ifp::Ethernet.new
    expect(hoge.on).to be true
    expect(hoge.power).to be true
    expect(hoge.off).to be false
    expect(hoge.power).to be false
    expect(hoge.respond_to?(:ready?)).to be true
    expect(hoge.respond_to?(:recv)).to be true
    expect(hoge.respond_to?(:send)).to be true
  end

  it "can send/recv Ethernet frame via #{name}" do
    frame = Nwdiy::Packet::Ethernet.new(src: "00:00:00:00:00:01",
                                        dst: "00:00:00:00:00:02")
    ifp0 = Nwdiy::Func::Ifp::Ethernet.new
    ifp1 = Nwdiy::Func::Ifp::Ethernet.new(ifp0.to_s)

    ifp0.on
    ifp1.on

    expect(ifp0.send(frame)).to be frame.bytesize
    expect(ifp0.sent).to be 1
    expect(ifp0.received).to be 0
    expect(ifp1.recv.to_pkt).to eq frame.to_pkt
    expect(ifp1.sent).to be 0
    expect(ifp1.received).to be 1

    expect { ifp0.send("hoge") }.to raise_error Nwdiy::Func::Ifp::Ethernet::EtherError
  end
end
