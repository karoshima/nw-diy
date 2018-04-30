#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
#
# モジュール変数には以下があります。
# - VERSION
#
################################################################

require "spec_helper"

RSpec.describe Nwdiy do
  it "has a version number" do
    expect(Nwdiy::VERSION).not_to be nil
  end

  it "sample 1" do
    skip 'eth2 のセグメントを、EtherIP を使って、eth1 の先の誰と繋ぐ'
  end
end
