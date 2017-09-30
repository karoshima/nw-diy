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
  @@template = Hash.new
  @@value = Hash.new

  def self.inherited(subcls)
    @@fields[subcls] = Array.new
    @@template[subcls] = ""
    @@value[subcls] = Hash.new
  end

  def self.def_field(type, *fields)

    case type
    when :uint8
      template = "C"
      cls = Integer
    when :uint16
      template = "n"
      cls = Integer
    when :uint32
      template = "N"
      cls = Integer
    when /^byte(\d+)$/
      template = "a#{$1}"
      cls = String
    when Nwdiy::Packet
      template = "a#{type.bytesize}"
      cls = type
    else
      raise TypeError.new("invalid type name '#{type}'")
    end

    fields.map! { |field|  field.to_sym }

    fields.each do |field|

      # サブクラスに定義順にフィールドを並べます
      @@fields[self] << [type, field]
      @@template[self] += template

      # サブクラスに読み書きメソッドを設定します
      case type
      when Symbol
        self.class_eval %Q{
          def #{field}
            @@value[self.class][:#{field}]
          end
          def #{field}=(data)
            @@value[self.class][:#{field}] = data
          end
        }
      when Nwdiy::Packet
        self.class_eval %Q{
          def #{field}
            @@value[self.class][:#{field}]
          end
          def #{field}=(data)
            @@value[self.class][:#{field}] = #{type}.new(data)
          end
        }
      end
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
      list = data.unpack(@@template[self.class] + "a*")
      @@fields[self.class].each do |cf|
        cls, field = cf
        case cls
        when Symbol
          @@value[self.class][field] = list.shift
        when Nwdiy::Packet
          @@value[self.class][field] = cls.new(list.shift)
        end
      end
      if self.respond_to?(:parse_data)
        self.parse_data(list.shift)
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
