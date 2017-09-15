#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# ruby 版 NW-DIY のトップモジュール
#
# 配下に以下のサブモジュール/サブクラスを持っています。
# - Nwdiy::Addr    アドレスモジュール群
# - Nwdiy::Packet  パケット群
# - Nwdiy::Func    パケット処理機能モジュール群
# - Nwdiy::Model   Nwdiy::Func のベースとなるモデル群
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

  # it "has some MACRO in Linux /usr/include/" do
  #   expect(Nwdiy::SOL_PACKET).not_to be nil
  #   expect(Nwdiy::ETH_P_ALL).not_to be nil
  #   expect(Nwdiy::PACKET_ADD_MEMBERSHIP).not_to be nil
  #   expect(Nwdiy::PACKET_DROP_MEMBERSHIP).not_to be nil
  #   expect(Nwdiy::PACKET_MR_PROMISC).not_to be nil
  #   expect(Nwdiy::etc("7/tcp")).to eq("echo")
  # end
end

# RSpec.describe String do
#   it "has btoh function" do
#     expect("\x00".btoh).to eq(0)
#     expect("\x00\x01".btoh).to eq(1)
#     expect("\x00\x01\x02".btoh).to eq(0x0102)
#     expect("\x00\x01\x02\x03".btoh).to eq(0x010203)
#     expect("\x00\x01\x02\x03\x04".btoh).to eq(0x01020304)
#   end
# end

# RSpec.describe Integer do
#   it "has htob function" do
#     expect(0x01.htob32).to eq("\x00\x00\x00\x01")
#     expect(0x01.htob16).to eq("\x00\x01")
#     expect(0x01.htob8).to eq("\x01")
#   end
#   it "has htonl, htons" do
#     expect(0x01.htonl).to eq(0x01000000)
#     expect(0x80000000.htonl).to eq(0x80)
#     expect(0x01.htons).to eq(0x0100)
#     expect(0x8000.htons).to eq(0x80)
#   end
# end
