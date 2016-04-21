#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require_relative '../nwdiy'

class NwDiy
  class Packet

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

    ################################################################
    # 最初に必要な NWDIY::PKT の子クラスを下記に定義しておく
    autoload(:Binary,   'nwdiy/packet/binary')
    autoload(:Ethernet, 'nwdiy/packet/ethernet')

    ################################################################
    # 定数 DATA_TYPE を使って、クラスからタイプ値を求める
    class KlassType
      # 変換テーブルを作っとく
      def initialize(hash)
        hash.kind_of?(Hash) or
          raise "Illegal hash data #{hash}"
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
      def type(klass)
        klass.kind_of?(Class) or klass = klass.class
        @type[klass]
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
    # エラー関連
    class TooShort < Exception; end
    class TooLong < Exception; end
    class InvalidData < Exception; end
  end

end
