#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# 練習問題 2.2. スイッチングハブ

require_relative "../lib/nwdiy"

require "nwdiy/vm"
require "nwdiy/timerhash"

class SwHub < NwDiy::VM
  # この VM は、インターフェース一覧を指定して作成する
  # 詳しくは NWDIY::VM の initialize を参照
  
  def initialize(*arg)
    super(*arg)

    @macdb = NwDiy::TimerHash.new
    @macdb.age = 10
    @macdb.update = false
  end

  # この VM の仕事内容は以下のとおり
  def job
    loop do
      rifp, rpkt = self.recv               # パケットを受信したら

      @macdb[rpkt.src] = rifp              # 受信インターフェースを覚える
      sifp = @macdb[rpkt.dst]              # 送信インターフェースが
      if sifp                              # もし分かったら
        sifp.send(rpkt)                    # そこにだけ送って
        next                               # ほかには送らない
      end

      self.iflist.each do |ifp|            # vm のインターフェースのうち
        (ifp == rifp) or                   # 受信インターフェース以外に
          ifp.send(rpkt)                   # パケットを送信する
      end
    end
  end
end
