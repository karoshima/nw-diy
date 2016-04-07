#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require_relative '../nwdiy'

class NWDIY
  class PKT

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
    # エラー関連
    class TooShort < Exception; end
    class TooLong < Exception; end
    class InvalidData < Exception; end
  end

end
