#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require "spec_helper"

################################################################
# 機能インスタンスの概要
################
# 各種ネットワーク機能 Nwdiy::Func::XXX の機能インスタンスは
# パケットを受信し操作し送信します。
#
################
# パイプとの関係
#
# NW-DIY には機能インスタンスをパイプで繋ぐ仕組みがあります。
# 機能によっては、パケットの向きを意識する必要があります。
#
# たとえば NAT では、パイプによって左側から来たパケットには、設定に沿っ
# てアドレス変換をかけて、右側から送信します。逆に右側から来たパケット
# には、内部的に保持している変換テーブルに沿ってアドレスを戻し、左側か
# ら送信します。
# 
# そのため Nwdiy::Func では、インスタンスの右側のインターフェースと左側
# のインターフェースを区別しています。区別の必要のない機能では、個別に
# 無視するようにします。
################################################################

RSpec.describe Nwdiy::Func do
  it "has receiving packet types" do
    expect(Nwdiy::Func::PKTTYPE_HOST).not_to be nil
    expect(Nwdiy::Func::PKTTYPE_BROADCAST).not_to be nil
    expect(Nwdiy::Func::PKTTYPE_MULTICAST).not_to be nil
    expect(Nwdiy::Func::PKTTYPE_OTHERHOST).not_to be nil
  end
end
