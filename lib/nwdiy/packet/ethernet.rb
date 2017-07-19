#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# Nwdiy::Packet::Ethernet はイーサネットフレームです
# 802.3 LLC や SNAP は将来検討です。
#
# 以下のメソッドで、フレーム種別を確認できます。
# - ethernet?
# 
# 以下のフィールドは、参照および代入が可能です。
# dst       送信先 MAC アドレス
# src       送信元 MAC アドレス
# data      データ
#
# 以下のフィールドは参照のみ可能です
# type
#
# そのほか Nwdiy::Packet の各種メソッドも使用可能です
################################################################

require "nwdiy/packet"

class Nwdiy::Packet::Ethernet
  include Nwdiy::Packet

  ################
  # イーサタイプと data のクラスとの変換テーブル
  TYPE = Hash.new

  def initialize(pkt = nil)
    case pkt
    when String
      raise TooShort.new("Ethernet", 14, pkt) unless pkt.bytesize > 14
      dst, src, type, data = pkt.unpack("a6a6na*")
      @dst = Nwdiy::Addr::Mac.new(dst)
      @src = Nwdiy::Addr::Mac.new(src)
      @type = type
      if TYPE[@type].kind_of?(Class)
        @data = TYPE[@type].new(pkt)
      else
        @data = pkt
      end
    when nil
      @dst = Nwdiy::Addr::Mac.new
      @src = Nwdiy::Addr::Mac.new
      @type = 0
      @data = ''
    end
  end

  ################
  # パケット内容の設定
  attr_accessor :dst, :src
  attr_reader :type, :data

  # データ部を設定します。
  # obj が Nwdiy::Packet::XXX 型を持つなら、type もそれに合わせて変更します。
  # obj が Nwdiy::Packet::XXX 型を持たないなら、type に合わせて型変換します。
  def data=(obj)
    if TYPE[obj.class]
      @type = TYPE[obj.class]
      @data = obj
    elsif TYPE[@type].kind_of?(Class)
      @data = TYPE[@type].new(obj)
    else
      @data = obj
    end
    @data.auto_compile = @auto_compile if @data.respond_to?(:auto_compile=)
  end

  ################
  # 自動計算の設定
  def auto_compile=(tf)
    @auto_compile = tf
    @data.auto_compile = tf if @data.respond_to?(:auto_compile=)
  end

  ################
  # パケットの扱い
  def to_s
    @dst.to_s + @src.to_s + @type.htob16 + @data.to_s
  end
  def inspect
    name = Nwdiy::etc(sprintf("%04x", @type))
    "[Ethernet #{@src.inspect} > #{@dst.inspect} #{name} #{@data.inspect}]"
  end
  def bytesize
    14 + @data.bytesize
  end

  # ethernet 形式であれば true を返します。
  def ethernet?
    @type > 1500
  end

end
