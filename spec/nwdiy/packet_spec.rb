#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# 各種パケットの抽象クラスです。イーサネットフレームや IP パケット,
# UDP パケット, など各種レイヤのフレーム/パケットは、このサブクラスとな
# ります。
#
#【サブクラスの作りかた】
#
# 単純なパケットの例
# class SubPacket < Nwdiy::Packet
#   def_field Nwdiy::Packet::Mac,  :dst, :src
#   def_field :uint16,             :type
#
#   def parse_data(data)
#     [@field1, @field2] = data.unpack("...")
#   end
#
#   def to_s
#     dst.to_s + src.to_s + vlan.map{|v|v.to_s} + type.to_s + data.to_s
#   end
#   def bytesize
#     to_s.bytesize
#   end
#   def inspect
#     "[xx:xx:xx:xx:xx:xx => xx:xx:xx:xx:xx:xx [xxx]]"
#   end
# end
#
# 一般的にパケットは、前半に固定長フィールドが配置され、
# 後半に可変長フィールドが配置されています。
#
# サブクラスを定義するときは、前半の固定長フィールド def_field 文で
# ひとつづつ定義し、後半の可変長フィールドを parse_data メソッドで
# 一気にパースします。
#
# 固定長フィールドの各項は、上記の例のように
# 「"def_field" 型, フィールド名」と定義します。
# フィールド名と同一名称の、インスタンス変数, 参照メソッド, 代入メソッド
# が生成されます。
#
# 型には以下の種類があります
#
#   固定長バイト列として :uint8, :uint16, :uint32, :uint64 があります。
#   このフィールドを参照すると、設定された値を Integer で返します。
#   このフィールドに代入する時は、Integer あるいはバイト列で設定できます。
#
#   Nwdiy::Packet のサブクラスを指定することもできます。
#   このフィールドを参照すると、指定したサブクラスのインスタンスを
#   返します。
#   このフィールドに代入する時は、指定したサブクラスのインスタンス
#   あるいはバイト列で設定できます。
#
#【このクラスの特異メソッド】
#
# calc_cksum(*args) -> Integer (16bit)
#    ひとつ以上の引数からチェックサムを計算します。
#
#【サブクラスで使える特異メソッド】
#
# new(string) -> SubPacket
#    recvmsg() などで受信したバイト列 (String) を SubPacket として読み、
#    生成したインスタンスを返します。
#
# new(キーワード引数) -> SubPacket
#    フィールド名ごとに値を指定して作成したインスタンスを返します。
#
#【サブクラスに定義する特異メソッド】
#
# template -> String
#    インスタンスを pack してバイト列を作ったり、
#    バイト列を unpack してインスタンスを作るための
#    pack テンプレート文字列を返してください。
#    省略時値は def_field などから自動生成します。
#
# size -> Integer
#    フィールドが固定長である場合に、そのバイトサイズを返してください。
#    省略時値は def_field などから自動生成します。
#
#【サブクラスのインスタンスメソッド】
#
# フィールド名 -> 型に対応した値
#    def_field で定義したフィールド名に設定された値を返します。
#    ただし、自動コンパイルが有効な場合には、
#    設定値ではなく :compile の計算結果を返します。
#    自動コンパイルについては、compile_flag を参照してください。
#
# フィールド名=(string) -> 型に対応した値, String
#    def_field で定義したフィールドに string から得た値を設定します。
#    def_array で定義したフィールド配列に string から得た値を設定します。
#    設定した値と余った string を返します。
#
# フィールド名=(value) -> 値
#    value が String ではない場合、
#    def_field で定義したフィールドに value を設定し、それを返します。
#
# to_s -> String
#    パケットをバイト列 (String) に変換します。
#
# bytesize -> Integer
#    パケットのバイトサイズを返します。
#
# inspect -> String
#    パケットを可読形式で返します。
#
# direction -> Symbol
#    パイプ内を進むパケットの向きを下記いずれかのシンボルで返します。
#    :to_left, :to_right, :unknown
#
################################################################

require "spec_helper"

RSpec.describe Nwdiy::Packet do
  it "calculate checksum" do
    data = ["\0\0\0\0\0\0\0\0", "\0\0\0\0\0\0\0\0"]
    expect(Nwdiy::Packet.calc_cksum(*data)).to be(0xffff)
  end

  it "create an packet field" do
    class Sample < Nwdiy::Packet
      def_field Nwdiy::Packet::Mac, :dst, :src
      def_field :uint16, :type
      def parse_data(data)
        @data = data
      end
    end
    src = "\0e\00\00\00\00\01"
    dst = "\0e\00\00\00\00\02"
    type = "\08\00"
    data = "Hello World"
    smpl = Sample.new(src + dst + type + data)
    expect(smpl.class).to be(Sample)
    expect(smpl.src).to be(src)
    expect(smpl.dst).to be(dst)
    expect(smpl.type).to be(type)
    expect(smpl.data).to be(data)
  end
end
