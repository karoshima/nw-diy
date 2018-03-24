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
end
