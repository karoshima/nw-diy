#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2017 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# ruby で綴る L2 switch
# 
# l2sw = NwDiy::L2Switch.new(インターフェース名あるいはインターフェース
#                            インスタンスのリスト)
#    接続するインターフェースを指定して L2 スイッチを作成します。
#        
# l2sw.iflist
#    インターフェース一覧を返します
# 
# l2sw.run
#    どれかのインターフェースから来たパケットを
#    別インターフェースに転送します。
# 
# l2sw.addif(インターフェースあるいはインターフェースのリスト)
#    インターフェースを追加します。
#
# l2sw.delif(インターフェースあるいはインターフェースのリスト)
#    インターフェースを削除します。
#
################################################################

require_relative '../../nwdiy'
require 'nwdiy/vm'
require 'nwdiy/timerhash'

module NwDiy
  class L2Switch < NwDiy::VM
  
    # この VM は、インターフェース一覧を指定して作成する
    # 詳しくは NWDIY::VM の initialize を参照
  
    def initialize(*args)
      super(*args)

      # L2switch には学習テーブルが必要
      @fdb = NwDiy::TimerHash.new
      @fdb.age = 600           # ageout は 600 秒
      @fdb.update = false      # 追加トラフィックでタイマ更新しない
      @fdb.autodelete = true   # ageout したら不要なのでそのまま削除
    end

    # この VM の仕事内容は以下のとおり
    def forward
      rifp, rpkt = self.recv    # パケットを受信する

      # 送信元 MAC と受信インターフェースを覚える
      if rpkt.src.unicast?
        @fdb[rpkt.src] = rifp
      end

      # 宛先 MAC がユニキャストであれば
      # その宛先 MAC で送信インターフェースを探す
      # 見つかれば、そのインターフェースだけに転送する
      if rpkt.dst.unicast?
        sifp = @fdb[rpkt.dst]
        if sifp
          sifp.send(rpkt)
          return
        end
      end

      # 送信先 MAC がマルチキャストの場合は
      #    IGMP/MLD snoop していれば転送先を絞る
      #    転送できない 01:80:C2:00:00:0x 宛は転送しない
      # 実装省略

      # 転送先インターフェースが分からない場合は
      # 全てのインターフェースに転送する
      self.iflist.each do |sifp|
        sifp.send(rpkt) if (sifp != rifp)
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
