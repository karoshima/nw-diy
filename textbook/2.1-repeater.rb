#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# 練習問題 2.1.リピータ

require_relative "../lib/vm"

class Repeater < NWDIY::VM
  # この VM は、インターフェース一覧を指定して作成する
  # 詳しくは NWDIY::VM の initialize を参照
  
  # この VM の仕事内容は以下のとおり
  def job
    loop do
      rifp, rpkt = self.recv               # パケットを受信したら
      self.ifp.delete(rifp).each do |ifp| # その他のインターフェースに
        ifp.send(rpkt)                     # パケットを送信する
      end
    end
  end
end
