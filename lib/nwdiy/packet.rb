#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require "nwdiy"

class Nwdiy::Packet

  autoload(:ARP,      'nwdiy/packet/arp')
  autoload(:Binary,   'nwdiy/packet/binary')
  autoload(:Ethernet, 'nwdiy/packet/ethernet')
  autoload(:IPv4Addr, 'nwdiy/packet/ipv4addr')
  autoload(:MacAddr,  'nwdiy/packet/macaddr')

  ################################################################
  # サブクラスを定義します

  @@headers = Hash.new
  @@types = Hash.new
  @@template = Hash.new
  @@hlen = Hash.new
  @@bodies = Hash.new
  @@classes = Hash.new

  def self.inherited(subcls)
    @@headers[subcls] = Array.new
    @@types[subcls] = Hash.new
    @@template[subcls] = ""
    @@hlen[subcls] = 0
    @@bodies[subcls] = Array.new
    @@classes[subcls] = Hash.new
  end

  # ヘッダフィールド定義
  def self.def_head(type, *fields)

    if type == :uint8
      size = 1
      template = "C"
      cls = Integer
    elsif type == :uint16
      size = 2
      template = "n"
      cls = Integer
    elsif type == :uint32
      size = 4
      template = "N"
      cls = Integer
    elsif type =~ /^byte(\d+)$/
      size = $1.to_i
      template = "a#{$1}"
      cls = String
    elsif type < Nwdiy::Packet
      size = type.bytesize
      template = "a#{type.bytesize}"
      cls = type
    else
      raise TypeError.new("invalid type name '#{type}'")
    end

    fields.map! { |field|  field.to_sym }

    fields.each do |field|

      # サブクラスに定義順にフィールドを並べます
      @@headers[self] << field
      @@types[self][field] = type
      @@template[self] += template
      @@hlen[self] += size

      # サブクラスに読み書きメソッドを設定します
      self.class_eval "
        def #{field}
          self.nwdiy_get(:#{field})
        end
        def #{field}=(data)
          self.nwdiy_set(:#{field}, data)
        end
      "
    end
  end

  # ボディフィールド定義
  def self.def_body (*fields)
    fields.each do |field|
      field = field.to_sym
      @@bodies[self] << field
      @@types[self][field] = :body
      self.class_eval "
        def #{field}
          self.nwdiy_get(:#{field})
        end
      "
    end
  end

  # ボディフィールドの型定義
  def self.def_body_type(field, classes)
    classes.update(classes.invert)
    @@classes[self][field.to_sym] = classes
  end

  ################################################################
  # サブクラスのインスタンスを生成します

  def initialize(data)
    @nwdiy_field = Hash.new
    case data
    when Hash
      data.each do |var, val|
        self.nwdiy_set(var.to_sym, val)
      end
    when String
      # ヘッダフィールドの切り出し
      values = data.unpack(@@template[self.class] + "a*")
      @@headers[self.class].each do |field|
        self.nwdiy_set(field, values.shift)
      end
      value = values.join
      @@bodies[self.class].each do |field|
        self.__send__("#{field}=", value)
        # 使ったぶん削る
        len = @nwdiy_field[field].bytesize
        value = value[len, value.bytesize-len]
      end
    end
  end

  # フィールドの読み書き
  def nwdiy_get(field)
    @nwdiy_field[field.to_sym]
  end
  def nwdiy_set(field, value)
    field = field.to_sym

    type = @@types[self.class][field]
    if type == nil
      raise "Unknown field #{field}"

    # ボディ部への代入なら、ユーザー定義にすべてを任せる
    elsif type == :body
      return self.__send__("#{field}=", value)

    # ヘッダ部への代入なら、ここで頑張る

    # 数値のときは uintX への代入だよね
    elsif value.kind_of?(Integer)
      unless @@types[self.class][field] =~ /^uint(\d+)$/
        raise TypeError.new "field #{field} is not an #{@@types.class} field"
      end
      return @nwdiy_field[field] = value

    # パケットデータなら、型一致だよね
    elsif value.kind_of?(Nwdiy::Packet)
      return @nwdiy_field[field] = value if
        value.kind_of?(@@types[self.class][field])
      raise "value #{value.inspect} is not a kind of #{@@types[self.class][field]}"

    # 文字列のときは型ごとの解釈
    elsif ! value.kind_of?(String)
      raise "Unknown type of data #{value.inspect}"
    elsif type == :uint8
      return @nwdiy_field[field] = value.unpack("C")[0]
    elsif type == :uint16
      return @nwdiy_field[field] = value.unpack("n")[0]
    elsif type == :uint32
      return @nwdiy_field[field] = value.unpack("N")[0]
    elsif type =~ /^byte(\d+)$/
      len = $1.to_i
      return @nwdiy_field[field] = value[0, len] if len <= value.bytesize
      return @nwdiy_field[field] = value + ("\x00" * (len - value.bytesize))
    elsif type < Nwdiy::Packet
      return @nwdiy_field[field] = @@types[self.class][field].new(value)
    end
  end
  

  # データからタイプ値を求める
  # タイプ値からデータを求める
  def body_type(field, type)
    self.class.body_type(field, arg)
  end
  def self.body_type(field, arg)
    case arg
    when Integer
      # 数値ならクラスを返す
      # クラスが文字列なら、クラス定数に変換してからね
      cls = @@classes[self][arg]
      return cls unless cls.kind_of?(String)
      cls = cls.split(/::/).inject(Module) { |c,s| c.const_get(s) }
      @@classes[self][arg] = cls
      return cls
    end
  end

  # パケットデータにする
  def to_pkt
    # ヘッダ部
    cls = self.class
    s = @@headers[cls].map {|h| @nwdiy_field[h] }.pack(@@template[cls])
    # ボディ部
    @@bodies[cls].inject(s) do |str, b|
      if @nwdiy_field[b].respond_to? :to_pkt
        s + @nwdiy_field[b].to_pkt
      else
        s + @nwdiy_field[b].to_s
      end
    end
  end
  # パケットを可視化する
  def inspect
    cls = self.class
    headers = @@headers[cls].map {|h| "#{h}="+@nwdiy_field[h].inspect }
    bodies = @@bodies[cls].map {|b| "#{b}="+@nwdiy_field[b].inspect }
    "[#{self.class.to_pkt} " + (headers + bodies).join(", ") + "]"
  end

  def bytesize
    @@bodies[self.class].inject(@@hlen[self.class]) do |sum, body|
      sum + @nwdiy_field[body].bytesize
    end
  end

  ################################################################
  # 以上ここまで未検証の書きかけ
  ################################################################

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
  class PacketTooShort < Exception # パケット生成時のデータ不足
    def initialize(name, minlen, pkt)
        super "#{name} needs #{minlen} bytes or longer, but the data has only #{pkt.bytesize} bytes."
    end
  end

  class Invalid < Exception; end  # パケット生成時の内容が変
end
