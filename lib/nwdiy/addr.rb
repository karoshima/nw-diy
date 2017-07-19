#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# Nwdiy::Addr::XXX の親モジュールです
# ここでは Nwdiy::Addr::XXX が持つメソッドについて
# ソースコード内に解説してあります。
################################################################

require "nwdiy"

module Nwdiy::Addr

  autoload(:Mac, 'nwdiy/addr/mac')

  ################
  # def to_s                    アドレスをバイナリ化します
  # def inspect                 アドレスを可視化します
  # def bytesize                アドレスの長さを返します
  ################

  ################
  # 例外クラス
  class TooShort < Exception # パケット生成時のデータ不足
    def initialize(name, minlen, pkt)
      super "#{name} needs #{minlen} bytes or longer, but the data has only #{pkt.bytesize} bytes."
    end
  end

  class Invalid < Exception; end  # パケット生成時の内容が変
end
