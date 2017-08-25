#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# Nwdiy::Packet は Nwdiy::Packet::XXX の親モジュールです。
# ここでは Nwdiy::Packet::XXX が持つメソッドについて
# ソースコード内に解説してあります。
#
# また、各種パケットは下記の属性を持っています。
#
# @autocompile      自動計算で求めるべきフィールドの計算を自動的に計算します。
#                   通常は true ですが、false にすると計算しません。
#
# @direction        パケットの向きを以下いずれかの値で示しています。
#                   :LEFT_TO_RIGHT 左から右へ
#                   :RIGHT_TO_LEFT 右から左へ
#                   :UNKNOWN       不明
# 
# copy_attributes   上記のフィールドを引数のパケットから取得します。
#
# その他、パケット処理で共通に使う機能をここで提供しています。
#
# calc_cksum()      チェックサムを計算します。
################################################################

require "nwdiy"

module Nwdiy::Packet

  autoload(:Binary,   'nwdiy/packet/binary')
  autoload(:Ethernet, 'nwdiy/packet/ethernet')

  ################################################################
  # Nwdiy::Packet::XXX に必要なメソッド

  def attr_init
    ################
    # パケットインスタンスの属性を初期化します。
    ################
    @auto_compile = true
    @direction = :UNKNOWN
  end

  attr_accessor :auto_compile
  attr_accessor :direction
  def dir_to_right
    self.direction = :LEFT_TO_RIGHT
  end
  def dir_to_left
    self.direction = :RIGHT_TO_LEFT
  end

  def copy_attributes(pkt)
    self.auto_compile = pkt.auto_compile if pkt.respond_to?(:auto_compile)
    self.direction    = pkt.direction    if pkt.respond_to?(:direction)
  end

  ################
  # パケット内容の設定
  # def フィールド名= val       パケットのフィールド値を設定します。
  # def フィールド名            パケットのフィールド値を参照します。
  ################

  ################
  # 自動計算の設定
  # def auto_compile = bool     パケットのフィールド自動計算を設定します。
  # def auto_compile            true なら自動計算します。
  ################

  ################
  # パケットの扱い
  # def to_s                    パケットをバイナリ化します。
  # def inspect                 パケットを可視化します。
  # def bytesize                パケットの長さを返します。
  ################

  ################
  # 複数のバッファからチェックサム計算します。
  def self.calc_cksum(*bufs)
    sum = bufs.inject(0) do |bufsum, buf|
      buf += "\x00" if buf.length % 2 == 1
      buf.unpack("n*").inject(bufsum, :+)
    end
    sum = (sum & 0xffff) + (sum >> 16) while sum > 0xffff;
    sum ^ 0xffff
  end

  ################
  # 例外クラス
  class TooShort < Exception # パケット生成時のデータ不足
    def initialize(name, minlen, pkt)
        super "#{name} needs #{minlen} bytes or longer, but the data has only #{pkt.bytesize} bytes."
    end
  end

  class Invalid < Exception; end  # パケット生成時の内容が変
end
