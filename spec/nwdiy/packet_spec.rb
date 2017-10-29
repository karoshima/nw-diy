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
#
# class Nwdiy::Packet
#   autoload(:ARP,  'nwdiy/packet/arp')
#   autoload(:IPv4, 'nwdiy/packet/ipv4')
#   autoload(:IPv6, 'nwdiy/packet/ipv6')
# end
#
# class SubPacket < Nwdiy::Packet
#
#   ################
#   # まずヘッダフィールドを順に定義します
#   # インスタンスメソッドで参照と代入が可能になります
#   # ちなみに実体は @nwdiy_field[フィールド名シンボル] です
#
#   def_head :uint32 :line1
#   def_head :uint16 :length
#   def_head :uint8  :next, :hlim
#   def_head Nwdiy::Packet::IPv6Addr, :src, :dst
#
#   ################
#   # 次にボディデータを定義します
#   # インスタンスメソッドで参照が可能になります
#   # 代入はパケットクラスごとに各自定義してください
#   # 実体は @nwdiy_field[フィールド名シンボル] です
#
#   def_body :data1, :data2, ...
#   def data1=(xxx)
#     @nwdiy_field[:data1] = ...
#   end
#
#   ################
#   # 多くの種類のパケットでは、ヘッダ上のタイプ値に沿って
#   # ボディデータの型が決まります。
#   # タイプ値とボディの型の対応表を def_body_type で定義しておくと
#   # ボディデータ代入メソッド定義のなかで、
#   # クラスメソッド body_type() を使うことで、
#   # body_type(フィールド名シンボル, タイプ値) でクラスが分かり、
#   # body_type(フィールド名シンボル, インスタンス) でタイプ値が分かります。
#
#   def_body_type :data1,
#                 1,  "Nwdiy::Packet::ICMP",
#                 6,  "Nwdiy::Packet::TCP",
#                 14  "Nwdiy::Packet::UDP"
#
#   def data2=(xxx)
#     case xxx
#     when String
#       @nwdiy_field[:data2] = self.class.body_type(:next, xxx)
#     when Nwdiy::Packet
#       self.type = self.class.body_type(xxx)
#     end
#   end
#
#   ################
#   # ヘッダやボディの再定義
#   # チェックサムや長さなど、上記の定義で生成されるメソッドを使わず
#   # 変更したいときは、def_head, def_body のあとに続けて
#   # メソッドを定義してください。
#   # フィールドに対応するデータは @nwdiy_field[フィールド名シンボル] です
#
#   def cksum
#     ...
#   end
#
#   ################
#   # インスタンスの実データ化, 可視化
#   # インスタンスをパケットデータに変換する to_s や
#   # インスタンスを可視化する inspect は
#   # 上記の def_head, def_body によって生成されています。
#   # 変更したいときは、def_head, def_body のあとに続けて
#   # メソッドを再定義してください。
#
#   def to_s
#     ...
#   end
#   def inspect
#     ...
#   end
#
################################################################
#
# def_head で使用する型には以下の種類があります
#
#   固定長バイト列として :uint8, :uint16, :uint32 があります。
#   このフィールドを参照すると、設定された値を Integer で返します。
#   このフィールドに代入する時は、Integer あるいは String で設定できます。
#
#   そのほか固定長のバイト列として :byteN (Nは整数) が使えます。
#   このフィールドを参照すると、設定された値を String で返します。
#   このフィールドに代入するときは、String で設定できます。
#
#   Nwdiy::Packet のサブクラスを指定することもできます。
#   このフィールドを参照すると、指定したサブクラスのインスタンスを
#   返します。
#   このフィールドに代入する時は、指定したサブクラスのインスタンス
#   あるいはバイト列で設定できます。
#
# ボディデータの型は一般的に、ヘッダフィールド中どれかの値によって
# 型とサイズが決まります。上述の def_body_type で対応表を定義して、
# body_type() で対応表を参照してください。
#
#【このクラスの特異メソッド】
#
# calc_cksum(*args) -> Integer (16bit)
#    ひとつ以上の引数からチェックサムを計算します。
#
#【サブクラスに定義する特異メソッド】
#
# def_head(type, *fields)
#
#    type 型の変数 name を定義します。
#    type には以下いずれかのシンボルを使うことができます。
#        :uint8     8 bit の Integer
#        :uint16   16 bit の Integer
#        :uint32   32 bit の Integer
#        :byteN    N byte の String
#    type はこれ以外に、Nwdiy::Packet の子クラスを指定することもできます。
#
#    fields には任意のシンボルを使うことができます。
#    ここに指定したシンボルはフィールド名となります。
#    そしてインスタンスメソッドとして代入や参照できるようになります。
#    インスタンスメソッド to_s や inspect に反映されます。
#
# def_body(*fields)
#
#    fields には任意のシンボルを使うことができます。
#    ここに指定したシンボルはフィールド名となります。
#    そしてインスタンスメソッドとして参照できるようになります。
#    インスタンスメソッド to_s や inspect に反映されます。
#
# def フィールド名=(xxx)
#   @nwdiy_field[フィールド名シンボル] = ...
# end
#
#    def_body では代入のインスタンスメソッドが生成されません。
#    なので自分で代入メソッドを定義し、そのなかで
#    @nwdiy_field[フィールドシンボル] に代入してください。
#
#【サブクラスで使える特異メソッド】
#
# new(string) -> SubPacket
#    recvmsg() などで受信したバイト列 (String) を SubPacket として読み、
#    生成したインスタンスを返します。
#
# new(Hash) -> SubPacket
#    フィールド名ごとに値を指定して作成したインスタンスを返します。
#
# body_type(フィールド名シンボル, 数値) -> Class
#
#    ヘッダフィールドに定義されたタイプ値から
#    ボディデータのクラスを返します。
#
# body_type(フィールド名シンボル, インスタンス) -> Integer
#
#    ボディデータに使用するインスタンスから
#    ヘッダフィールドのタイプ値として使うべき数値を返します
#
# bytesize -> String
#    サブクラス定義が def_head 定義のみで def_body 定義がない場合、
#    パケット長が分かるのでその長さを返します。
#    def_body 定義もある場合は、パケット長が分からないので nil を返します。
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
# フィールド名=(value) -> value
#    def_field で定義したフィールドに value を設定し、それを返します。
#
#【サブクラスで使えるインスタンスメソッド】
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

  it "creates an packet field" do

    class Sample01 < Nwdiy::Packet
      def_head :byte6, :dst, :src
      def_head :uint16, :type
      def_body :data
      def data=(val)
        @nwdiy_field[:data] = val
      end
    end

    dst = "\x00\x00\x0e\x00\x00\x01"
    src = "\x00\x00\x0e\x00\x00\x02"
    type = "\x08\x00"
    data = "Hello World"
    pkt = dst + src + type + data
    smpl = Sample01.new(pkt)

    expect(smpl).to be_a Sample01
    expect(smpl.dst).to eq(dst)
    expect(smpl.src).to eq(src)
    expect(smpl.type).to eq(0x0800)
    expect(smpl.data).to eq(data)
    expect(smpl.to_s).to eq(pkt)
    expect(smpl.bytesize).to eq(pkt.bytesize)
  end

  it "creates an packet which include Nwdiy::Packet parts" do

    class Sample02 < Nwdiy::Packet
      def_head Nwdiy::Packet::MacAddr, :dst, :src
      def_head :uint16, :type
      def_body :data
      def data=(xxx)
        @data = xxx
      end
    end

    dst = "\x00\x00\x0e\x00\x00\x01"
    src = "\x00\x00\x0e\x00\x00\x02"
    type = "\x08\x00"
    data = "Hello World"
    smpl = Sample02.new(dst + src + type + data)

    expect(smpl).to be_a(Sample02)
    expect(smpl.dst.to_s).to eq(dst)
    expect(smpl.src.to_s).to eq(src)
    expect(smpl.dst.inspect).to eq("00:00:0e:00:00:01")
    expect(smpl.src.inspect).to eq("00:00:0e:00:00:02")
    expect(smpl.type).to eq(0x0800)
    expect(smpl.data).to eq(data)
  end

end
