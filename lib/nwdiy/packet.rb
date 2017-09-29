#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require "nwdiy"

class Nwdiy::Packet

  autoload(:Binary, 'nwdiy/packet/binary')

  ################################################################
  # サブクラスを定義します

  @@fields = Hash.new

  def self.inherited(subcls)
    @@fields[subcls] = Array.new
    @@template[subcls] = ""
  end

  def self.def_field(type, *fields)

    raise TypeError.new("invalid type name '#{type}'") unless
      type.kind_of?(Nwdiy::Packet) || type == :uint8 ||
      type == :uint16 || type == :uint32 || type == :uint64

    fields.each do |field|
      raise TypeError.new("invalid field name '#{name}'") unless
        name.kind_of?(Symbol)
    end

    fields.each do |field|

      # サブクラスに定義順にフィールドを並べます
      @@fields[self] << [type, name]
      @@template[self] += type.template

      # サブクラスに読み書きメソッドを設定します
      self.class_eval %Q {
        @#{field}
        def #{field}
          @#{field}
        end
        def #{field}=(data)
          @#{field} = #{type}.new(data)
        end
      }
    end
  end

  ################################################################
  # サブクラスのインスタンスを生成します

  def initialize(data)
    case data
    when Hash
      data.each do |var, val|
        self.instance_variable_set(var, val)
      end
    when String
      fixed = data.unpack(@@template[self])
      @@fields[self].each do |tf|
        type, field = tf
        self.instance_variable_set(field, type.new(fixed.shift))
      end
      if self.respond_to?(:parse_data)
        self.parse_data(fixed.shift)
      end
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
