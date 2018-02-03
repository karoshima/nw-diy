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
end
