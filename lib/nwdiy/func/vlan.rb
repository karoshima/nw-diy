#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2017 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# ruby で綴る VLAN
# 
#    1 本の trunk インターフェース に届く VLAN パケットを
#    vlan-id ごとの access インターフェースに分配します。
#    また逆に access インターフェースに届く Ethernet パケットに
#    VLAN にして trunk インターフェースに流します。
#
# インスタンス作成方法
#
#  vlan = NwDiy::VLAN.new
#    VLAN スイッチを作成します (引数はありません)
#
# 使いかた
# 
#  vlan[<id>] = インターフェース名あるいはインターフェースインスタンス
#    vlan-id を指定して access インターフェースを登録します。
#
#  vlan.trunk = インターフェース名あるいはインターフェースインスタンス
#    trunk インターフェースを登録します。
#
#  vlan.run
#    access インターフェースで受信した Ethernet frame に
#    vlan タグを付与して trunk インターフェースに転送します。
#    trunk インターフェースで受信した Ethernet frame から
#    vlan タグを削除し、vlan-id に対応する access インターフェースに
#    転送します。
#
################################################################

require_relative '../../nwdiy'
require 'nwdiy/vm'

module NwDiy
  class VLAN < NwDiy::VM

    def initialize
      super()
      @klass = NwDiy::Packet::VLAN
      @trunk = nil
      @access = Hash.new
      @vid = Hash.new
    end

    # VLAN の型 (QinQ に変更もできるよ)
    attr_accessor :klass

    # trunk インターフェース
    attr_reader :trunk
    def trunk=(ifp)
      self.delif(@trunk) if @trunk
      @trunk = self.addif(ifp)
    end

    # access インターフェース
    def [](vid)
      @access[vid]
    end
    def []=(vid, ifp)
      raise Errno::ENODEV.new("vlan-id #{vid} is invalid") unless
        (0 < vid && vid < 4095)
      self.delif(@access[vid]) if @access[vid]
      return unless ifp
      @access[vid] = self.addif(ifp)
    end

    # この VM の仕事は以下のとおり
    def forward
      rifp, rpkt = self.recv

      if (rifp == @trunk)
        # trunk ポートで受信した場合
        return unless rpkt.kind_of?(NwDiy::Packet::Ethernet)
        vlan = rpkt.data
        return unless vlan.kind_of?(NwDiy::Packet::VLAN)
        return if vlan.cfi
        sifp = @access[vlan.vid]
        return unless sifp
        rpkt.data = vlan.data
        sifp.send(rpkt)
      else
        # access ポートで受信した場合
        return unless rpkt.kind_of?(NwDiy::Packet::Ethernet)
        vid = @access.key(rifp)
        return unless vid
        vlan = @klass.new
        vlan.vid = vid
        vlan.data = rpkt.data
        rpkt.data = vlan
        @trunk.send(rpkt)
      end
    end

    # スレッドかなにかでずっと動かし続ける
    def run
      loop do
        self.forward
      end
    end
  end
end
