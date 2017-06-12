#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
#
# NwDiy::Packet は NwDiy::Packet::XXX の親クラスです。
# ここでは NwDiy::Packet::XXX が持つべきメソッドについて
# ソースコード内に解説してあります。
# 
# また、各種パケット共通で使用する機能について定義しています
# 
# @autocompile      通常は真ですが、この値を偽にすることで
#                   自動計算で求められるフィールドの計算をやめます。
# class Klasstype   パケットのタイプ値と、パケットのデータ部のクラスの
#                   対応表を管理します。
# def calc_cksum    チェックサムを計算します。
# calss TooShort    パケット長不足のエラーを表します
#
################################################################

require_relative '../nwdiy'

module NwDiy
  module Packet

    ################################################################
    # NWDIY::PKT::* に必要な定数
    # DATA_TYPE = { タイプ値 => データ部のクラス }
    #    バイナリデータからタイプ値を求めたり
    #    タイプ値の入力を受けてバイナリデータを書き換えたり
    #    するのに使う

    ################################################################
    # NWDIY::PKT::* に必須なメソッド

    # def initialize(packet_binary)
    #    受信したパケットを元に NWDIY::PKT を作る
    # end
    # def initialize
    #    中身のない NWDIY::PKT を作る
    # end
    # 引数の有無に関わらず、内部で super() すること
    def initialize
      @auto_compile = true
    end

    # def フィールド名=(val)
    #    NWDIY::PKT の特定フィールドのデータを設定する
    #    nil を設定すると、元のデータを破棄する
    # end
    # def フィールド名
    #    NWDIY::PKT の特定フィールドのデータを参照する
    # end

    # def to_pkt
    #   パケットデータである String を出力する
    # end

    # def bytesize
    #    パケットデータのサイズを返す
    # end

    # def to_s
    #   パケットを可視化する
    # end

    attr_reader :auto_compile
    #   パケット内容を出力するとき、自動算出できるフィールドに関して
    #   自動算出する (真) あるいはしない (偽) を確認する。
    #   あるいは設定する (設定は子クラスそれぞれで定義)

    ################################################################
    # 最初に必要な NWDIY::PKT の子クラスを下記に定義しておく
    autoload(:Binary,   'nwdiy/packet/binary')
    autoload(:Ethernet, 'nwdiy/packet/ethernet')

    ################################################################
    # 各種パケットクラス定義につかうデータ
    # 定数 DATA_TYPE を使って、クラスからタイプ値を求める
    class KlassType
      # 変換テーブルを作っとく
      def initialize(hash)
        raise "Illegal hash data #{hash}" unless hash.kind_of?(Hash)
        @type = Hash.new
        @klass = Hash.new(Binary)
        hash.each do |key,val|
          if    key.kind_of?(Class) && val.kind_of?(Integer)
            @type[key] = val
            @klass[val] = key
          elsif val.kind_of?(Class) && key.kind_of?(Integer)
            @type[val] = key
            @klass[key] = val
          end
        end
      end

      # データからタイプ値を求める
      def type(klass, nomatch = nil)
        unless klass.kind_of?(Class)
          klass = klass.class
        end
        @type[klass] || nomatch || 0
      end

      # タイプ値からデータクラスを求める
      def klass(type)
        @klass[type]
      end

      # debug
      def to_s
        "[#@type] [#@klass]"
      end
    end

    ################################################################
    # チェックサム計算する with 与えられた複数のバッファ
    def calc_cksum(*bufs)
      sum = bufs.inject(0) do |sum2,buf|
        if (buf.length % 2 == 1)
          buf += "\x00"
        end
        buf.unpack("n*").inject(sum2, :+)
      end
      sum = (sum & 0xffff) + (sum >> 16) while sum > 0xffff;
      sum ^ 0xffff
    end

    ################################################################
    # エラー関連
    class TooShort < Exception
      def initialize(name, minlen, pkt)
        super "#{name} needs #{minlen} bytes or longer, but the data has only #{pkt.bytesize} bytes."
      end
    end
    class TooLong < Exception; end
    class InvalidData < Exception; end
  end

end
