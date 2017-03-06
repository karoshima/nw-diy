#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2017 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# ruby で綴る VLAN

require_relative '../../nwdiy'
require 'nwdiy/vm'

module NwDiy
  class VLAN < NwDiy::VM

    def initialize
      super()
      @klass = NwDiy::Packet::VLAN
      @trunk = nil
      @access = Array.new
      @vid = Hash.new
    end

    # VLAN の型 (QinQ に変更もできるよ)
    attr_accessor :klass

    # trunk インターフェース
    attr_reader :trunk
    def trunk=(ifp)
      @trunk and
        self.delif(@trunk)
      @trunk = self.addif(@trunk)
    end

    # access インターフェース
    def [](vid)
      @access[vid]
    end
    def []=(vid, ifp)
      (0 < vid) or
        raise Errno::ENODEV.new("vlan-id #{vid} is invalid");
      @access[vid] and
        self.delif(@access[vid])
      ifp or return
      @access[vid] = self.addif(ifp)
    end

    # この VM の仕事は以下のとおり
    def forward
      rifp, rpkt = self.recv

      if (rifp == @trunk)
        # trunk ポートで受信した場合
        rpkt.kind_of?(NwDiy::Packet::Ethernet) or
          return
        vlan = rpkt.data
        vlan.kind_of?(NwDiy::Packet::VLAN) or
          return
        vlan.cfi and
          return
        sifp = @access[vlan.vid]
        sifp or
          return
        rpkt.data = vlan.data
        sifp.send(rpkt)
      else
        vid = @access.key(rifp) or
          return
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
