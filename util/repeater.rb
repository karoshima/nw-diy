#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# ruby で綴る、簡易で adhoc な、リピータ
################################################################
# repeater = NwDiy::Repeater.new(ifp [, ifp, ifp...])
#    インターフェース ifp たちを結ぶリピータ
#    スイッチではなく、MAC アドレスの学習は行なわない
# repeater.run
#    強制終了させられるまで、リピータ動作する
# repeater.start
#    スレッドでリピータ動作を開始する

require_relative '../lib/nwdiy'

require 'nwdiy/vm'

module NwDiy
  class Repeater < NwDiy::VM
    # この VM は、インターフェース一覧を指定して作成する
    # 詳しくは NWDIY::VM の initialize を参照
  
    # この VM の仕事内容は以下のとおり
    def run
      loop do
        rifp, rpkt = self.recv               # パケットを受信したら
        puts "#{rifp} => #{rpkt}"            # 表示してから
        self.iflist.each do |ifp|            # vm のインターフェースのうち
          unless (ifp == rifp)               # 受信インターフェース以外に
            ifp.send(rpkt)                   # パケットを送信する
          end
        end
      end
    end
  end
end
