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

    # def compile(overwrite=false)
    #    設定されたデータを元に、設定されてないデータを補完する
    #    不整合があれば、それを raise するか、もしくは
    #    数値を overwrite する
    #    ICMP などの不完全データを含むパケットを扱うときは、
    #    呼び出し元で rescue TooShort で対応してもらう
    #    返値は self
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
    module Util
      @@types = nil
      @@klass = nil
      def class2type(cls)
        cls.kind_of?(Class) or cls = cls.class
        @@types or self.check_data_type
        @@types[cls]
      end
      def type2class(id)
        @@klass or self.check_data_type
        @@klass[id]
      end
      def check_data_type
        table = self.data_type
        table.kind_of?(Hash) or
          raise "Illegal hash data #{table}"
        @@types = Hash.new
        @@klass = Hash.new(Binary)
        table.each do |key,val|
          if    key.kind_of?(Class) && val.kind_of?(Integer)
            @@types[key] = val
            @@klass[val] = key
          elsif key.kind_of?(Integer) && val.kind_of?(Class)
            @@types[val] = key
            @@klass[key] = val
          end
        end
      end
    end

    ################################################################
    # エラー関連
    class TooShort < Exception; end
    class TooLong < Exception; end
    class InvalidData < Exception; end
  end

end
