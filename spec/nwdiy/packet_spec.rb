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
#   def_field Nwdiy::Packet::Mac,  :dst, :src
#   def_field :uint16,             :type
#
#   def_typed_field :type, :data,
#     0x0800 => "Nwdiy::Packet::IPv4",
#     0x0806 => "Nwdiy::Packet::ARP",
#     0x8100 => "Nwdiy::Packet::VLAN",
#     0x86dd => "Nwdiy::Packet::IPv6"
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
# サブクラスを定義するときは、まず前半の固定長フィールドを 
# def_field 文で定義し、続けて可変長フィールドを
# インスタンスメソッドやインスタンス変数として定義します。
# def_field 文で定義したフィールドは、インスタンスメソッドや
# インスタンス変数として参照できます。
#
# パケットのバイナリデータからパケットインスタンスを作成するとき、
# 前半の固定長フィールドは自動的に設定されます。
# 固定長フィールドで使用しなかった後半のデータは
# 各クラスで定義する parse_data() メソッドに渡されます。
# このメソッドでは、後半の可変長フィールドを設定してください。
#
# 型には以下の種類があります
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
# ありがちなパケットの形態として、タイプ値によって後続データの型が決まる
# というものがあります。
# そのときは def_field ではなく def_typed_field を使用して、
# タイプとして扱うフィールドのフィールド名シンボル,
# データとして扱うフィールドのフィールド名シンボル,
# 続けてタイプとデータの対応表をハッシュで設定します。
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
# new(Hash) -> SubPacket
#    フィールド名ごとに値を指定して作成したインスタンスを返します。
#
#【サブクラスに定義する特異メソッド】
#
# def_field(type, *name)
#    type 型の変数 name を定義します。
#    type には以下いずれかのシンボルを使うことができます。
#        :uint8    8 bit 整数
#        :uint16  16 bit 整数
#        :uint32  32 bit 整数
#        :byteN    N byte データ
#    type はこれ以外に、Nwdiy::Packet の子クラスを指定することもできます。
#    name には任意のシンボルを使うことができます。
#    ここに指定したシンボルはフィールド名となり、
#    インスタンス変数として、そしてインスタンスメソッドとして、
#    代入や参照できます。
#
# def_typed_field(type, name, hash)
#    type には def_field で指定した数値フィールド名をシンボルで指定します。
#    name は def_field と同様に変数名となります。
#    hash には type 値と name クラスの対応表を指定します。
#    このハッシュには、クラスそのものではなく文字列で記載することもできます。
#    文字列で記載することで、起動時にライブラリをすべて読み込んで
#    しまうのでなく、必要なクラスだけ遅延読み込みにすることができます。
#
# bytesize -> String
#    固定長のサブクラスでは、そのバイト長を返してください。
#    可変長のサブクラスでは、nil を返してください。
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
#【サブクラスに定義するインスタンスメソッド】
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
      def_field :byte6, :dst, :src
      def_field :uint16, :type
      def parse_data(data)
        @data = data
      end
      attr_accessor :data
    end

    dst = "\x00\x00\x0e\x00\x00\x01"
    src = "\x00\x00\x0e\x00\x00\x02"
    type = "\x08\x00"
    data = "Hello World"
    smpl = Sample01.new(dst + src + type + data)

    expect(smpl.class).to be(Sample01)
    expect(smpl.dst).to eq(dst)
    expect(smpl.src).to eq(src)
    expect(smpl.type).to eq(0x0800)
    expect(smpl.data).to eq(data)
  end

  it "creates an packet which include Nwdiy::Packet parts" do

    class Sample02 < Nwdiy::Packet
      def_field Nwdiy::Packet::MacAddr, :dst, :src
      def_field :uint16, :type
      def parse_data(data)
        @data = data
      end
      attr_accessor :data
    end

    dst = "\x00\x00\x0e\x00\x00\x01"
    src = "\x00\x00\x0e\x00\x00\x02"
    type = "\x08\x00"
    data = "Hello World"
    smpl = Sample02.new(dst + src + type + data)

    expect(smpl.class).to be(Sample02)
    expect(smpl.dst.to_s).to eq(dst)
    expect(smpl.src.to_s).to eq(src)
    expect(smpl.dst.inspect).to eq("00:00:0e:00:00:01")
    expect(smpl.src.inspect).to eq("00:00:0e:00:00:02")
    expect(smpl.type).to eq(0x0800)
    expect(smpl.data).to eq(data)
  end

  it "creates an packet which uses def_typed_field" do
    class Nwdiy::Packet
      autoload(:MacAddr,  'nwdiy/packet/macaddr')
      autoload(:IPv4Addr, 'nwdiy/packet/ipv4addr')
    end
    class Sample03 < Nwdiy::Packet
      def_field :uint8, :type
      def_typed_field :type, :addr,
                      1 => "Nwdiy::Packet::MacAddr",
                      2 => "Nwdiy::Packet::IPv4Addr"
    end

    smpl1 = Sample03.new("\x01" + "\x80\x81\x82\x83\x84\x85")
    expect(smpl1).to be_a Sample03
    expect(smpl1.type).to eq 1
    expect(smpl1.data).to be_a Nwdiy::Packet::MacAddr

    smpl2 = Sample03.new("\x02" + "\x80\x81\x82\x83")
    expect(smpl1).to be_a Sample03
    expect(smpl1.type).to eq 2
    expect(smpl1.data).to be_a Nwdiy::Packet::IPv4Addr

    smpl3 = Sample03.new
    smpl3.data = Nwdiy::Packet::MacAddr.new("00:00:0e:00:00:01")
    expect(smpl3.type).to be 1

    smpl3.data = Nwdiy::Packet::IPv4Addr.new("1.1.1.1")
    expect(smpl3.type).to be 2
  end
end
