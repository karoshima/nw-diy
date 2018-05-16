#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

class Nwdiy::Packet

  autoload(:Binary,   'nwdiy/packet/binary')
  autoload(:Ethernet, 'nwdiy/packet/ethernet')
  autoload(:MacAddr,  'nwdiy/packet/macaddr')
  autoload(:VLAN,     'nwdiy/packet/vlan')
  autoload(:IPv4,     'nwdiy/packet/ipv4')
  autoload(:IPv4Addr, 'nwdiy/packet/ipv4addr')
  autoload(:ARP,      'nwdiy/packet/arp')
  autoload(:IPv6,     'nwdiy/packet/ipv6')
  autoload(:IPv6Addr, 'nwdiy/packet/ipv6addr')
  autoload(:UDP,      'nwdiy/packet/udp')
  autoload(:ICMP4,    'nwdiy/packet/icmp4')

  include Nwdiy::Debug

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
  def self.def_body(*fields)
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

  def initialize(data = nil, default = {})
    @nwdiy_field = Hash.new
    if data.kind_of?(String)
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
    else
      if data.kind_of?(Hash)
        data = default.merge(data)
      else
        data = default
      end
      data.each do |var, val|
        self.nwdiy_set(var.to_sym, val)
      end
    end
  end

  # フィールドの読み書き
  def nwdiy_get(field)

    field = field.to_sym
    return @nwdiy_field[field] if @nwdiy_field[field]

    type = @@types[self.class][field]

    if type =~ /^uint/
      self.nwdiy_set(field, 0)
    elsif type =~ /^byte(\d+)$/
      self.nwdiy_set(field, "\x00" * $1.to_i)
    elsif type.kind_of?(Class) && type < Nwdiy::Packet
      self.nwdiy_set(field, nil)
    end
    return @nwdiy_field[field]
  end
  def nwdiy_set(field, value)
    field = field.to_sym

#    debug "#{field} = #{value}(#{value.class})"

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

    # Nwdiy::Packet 型のときは、nil 初期化や Hash 初期化もあり得る
    elsif (value == nil || value.kind_of?(Hash)) && type.kind_of?(Class) && type < Nwdiy::Packet
      return @nwdiy_field[field] = type.new(value)
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
      return @nwdiy_field[field] = type.new(value)
    end
  end
  

  # データからタイプ値を求める
  # タイプ値からデータを求める
  def body_type(field, type)
    self.class.body_type(field, type)
  end
  def self.body_type(field, arg)
    case arg
    when Integer
      # 数値ならクラスを返す
      # クラスが文字列なら、クラス定数に変換してからね
      cls = @@classes[self][field][arg]
      return Nwdiy::Packet::Binary unless cls
      return cls unless cls.kind_of?(String)
      cls = cls.split(/::/).inject(Module) { |c,s| c.const_get(s) }
      @@classes[self][field][arg] = cls
      return cls
    when Nwdiy::Packet
      type = @@classes[self][field][arg.class]
      return type if type
      type = @@classes[self][field][arg.class.to_s]
      return 0 unless type
     return @@classes[self][field][arg.class] =
        @@classes[self][field].delete(arg.class.to_s)
    end
  end

  # パケットデータにする
  def to_pkt(head: true, body: true)
    cls = self.class
    # ヘッダ部
    if head
      s = @@headers[cls].map do |h|
        field = self.nwdiy_get(h)
        field.kind_of?(Nwdiy::Packet) ? field.to_pkt : field
      end
      sp = s.pack(@@template[cls])
    else
      sp = ""
    end
    # ボディ部
    if body
      @@bodies[cls].each do |b|
        if @nwdiy_field[b].respond_to? :to_pkt
          sp += @nwdiy_field[b].to_pkt
        else
          sp += @nwdiy_field[b].to_s
        end
      end
    end
    return sp
  end
  # パケットを可視化する
  def inspect
    cls = self.class
    headers = @@headers[cls].map {|h| "#{h}="+@nwdiy_field[h].inspect }
    bodies = @@bodies[cls].map {|b| "#{b}="+@nwdiy_field[b].inspect }
    "[#{self.class.to_s} " + (headers + bodies).join(", ") + "]"
  end
  # パケットを Hash 化する
  def to_hash
    cls = self.class
    hash = Hash.new
    (@@headers[cls] + @@bodies[cls]).each { |h| hash[h] = @nwdiy_field[h] }
    hash
  end

  def bytesize
    @@bodies[self.class].inject(@@hlen[self.class]) do |sum, body|
      sum + (@nwdiy_field[body]&.bytesize || 0)
    end
  end

  # パケット送受信インターフェース
  def from
    @from
  end
  def from=(ifp)
    return @from = ifp if ifp == nil
    return @from = ifp if ifp.kind_of?(Nwdiy::Func::Ifp)
    raise NotInterfaceError.new "#{ifp}(#{ifp.class}) must be Nwdiy::Func::Ifp instance"
  end
  def to
    @to
  end
  def to=(ifp)
    return @to = ifp if ifp == nil
    return @to = ifp if ifp.kind_of?(Nwdiy::Func::Ifp)
    if ifp.kind_of?(Array)
      ifp.compact!
      if ifp.all? { |ifpp| ifpp.kind_of?(Nwdiy::Func::Ifp) }
        return @to = ifp
      end
    end
    raise NotInterfaceError.new "#{ifp}(#{ifp.class}) must be Nwdiy::Func::Ifp instance"
  end

  ################
  # 複数のバッファからチェックサム計算します。
  def self.calc_cksum(*bufs)
    sum  = bufs.map {|b1| (b1+"\x00").unpack("n*") }.flatten.inject(0, :+)
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

  class NotInterfaceError < Exception; end  # 送受信インターフェースおかしい
end
