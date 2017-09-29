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
#   def_field Nwdiy::Packet::Mac,  :dst
#   def_field Nwdiy::Packet::Mac,  :src
#   def_field :uint16,             :type
#   def_field :datatype            :data
#
#   def datatype(data)
#     return Nwdiy::Packet::IPv4
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
# 上記のように 「"def_field" 型, フィールド名, オプション」と定義します。
# 事前に型が決まらない箇所では、型を求めるインスタンスメソッドを
# 記載することも可能です。
#
# 型には以下の種類があります
#
#   固定長バイト列として uint8, uint16, uint32, uint64 があります。
#   このフィールドを参照すると、設定された値を Integer で返します。
#   このフィールドに代入する時は、Integer あるいはバイト列で設定できます。
#
#   Nwdiy::Packet のサブクラスを指定することもできます。
#   このフィールドを参照すると、指定したサブクラスのインスタンスを
#   返します。
#   このフィールドに代入する時は、指定したサブクラスのインスタンス
#   あるいはバイト列で設定できます。
#
#   型が可変なフィールドについては、型を求めるインスタンスメソッドを
#   指定することができます。
#   このフィールドを参照すると、何らかの Nwdiy::Packet サブクラスの
#   インスタンスを返します。
#   このフィールドに Nwdiy::Packet サブクラスのインスタンスを代入
#   することができます。このとき、型を求めるインスタンスメソッドは
#   インスタンスのクラスが適切かどうかチェックし、適切であれば
#   それに合わせてインスタンス内の他のフィールドも修正します。
#   このフィールドにバイト列を代入することもできます。このとき
#   型を求めるインスタンスメソッドによって、型が決まります。
#
# オプションはハッシュ形式で設定します。
# 以下のパラメーターを指定できます。
#
#   length: 配列サイズ
#      def_array で定義する配列のサイズが固定である場合に
#      その配列サイズを記載します。
#      def_field では効力を持ちません。
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
#    pack テンプレート文字列を返します。
#    省略時値は def_field などから自動生成します。
#    変更したくなると思えないので、隠しメソッドでいいかな・・・
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

  # it 'has a direction' do
  #   data =
  #     "\x00\x00\x0e\x00\x00\x01" + # eth dst
  #     "\x00\x00\x0e\x00\x00\x02" + # eth src
  #     "\x08\x00" +                 # eth type
  #     "\x45\x00\x00\x54\xf1\x18" + # IPv4 vhl, tos, len, id
  #     "\x40\x00\x40\x01\x31\x80" + # IPv4 frag, ttl, proto, cksum
  #     "\x0a\x00\x02\x0f" +         # IPv4 src
  #     "\x0a\x00\x02\x02" +         # IPv4 dst
  #     "\x08\x00\xc3\x7c" +         # ICMP type, code, cksum
  #     "\x24\x5b\x00\x01" +         # ICMP id, seq
  #     "\x9e\x3e\x9d\x59\0\0\0\0" + # ICMP timestamp
  #     "\x10\xbc\x05\x00\0\0\0\0" +         # ICMP data
  #     "\x10\x11\x12\x13\x14\x15\x16\x17" + # ICMP data
  #     "\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f" + # ICMP data
  #     "\x20\x21\x22\x23\x24\x25\x26\x27" + # ICMP data
  #     "\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f" + # ICMP data
  #     "\x20\x31\x32\x33\x34\x35\x36\x37" + # ICMP data
  #     ""
  #   pkt = Nwdiy::Packet::Ethernet.new(data)
  #   expect(pkt.class).to be Nwdiy::Packet::Ethernet
  #   expect(pkt.auto_compile).to be true
  #   expect(pkt.data.auto_compile).to be true
  #   expect(pkt.direction).to be :UNKNOWN
  #   expect(pkt.data.direction).to be :UNKNOWN

  #   pkt.auto_compile = false
  #   expect(pkt.auto_compile).to be false
  #   expect(pkt.data.auto_compile).to be false

  #   pkt.dir_to_right
  #   expect(pkt.direction).to be :LEFT_TO_RIGHT
  #   expect(pkt.data.direction).to be :LEFT_TO_RIGHT
  # end
end
