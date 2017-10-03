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
  autoload(:Mac,    'nwdiy/packet/mac')

  ################################################################
  # サブクラスを定義します

  @@fields = Hash.new
  @@template = Hash.new

  def self.inherited(subcls)
    @@fields[subcls] = Array.new
    @@template[subcls] = ""
  end

  def self.def_field(type, *fields)

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
      template = "a#{$1}"
      cls = String
    elsif type < Nwdiy::Packet
      template = "a#{type.bytesize}"
      cls = type
    else
      p TypeError.new("invalid type name '#{type}'")
      raise TypeError.new("invalid type name '#{type}'")
    end

    fields.map! { |field|  field.to_sym }

    fields.each do |field|

      # サブクラスに定義順にフィールドを並べます
      @@fields[self] << [type, field]
      @@template[self] += template

      # サブクラスに読み書きメソッドを設定します
      if type =~ /^uint/
        self.class_eval %Q{
          def #{field}
            @#{field}
          end
          def #{field}=(data)
            if data.kind_of?(Integer)
              @#{field} = data
            elsif data.bytesize == #{size}
              @#{field} = data.unpack("#{template}")[0]
            else
              @#{field} = data.to_i
            end
          end
        }
      elsif type =~ /^byte(\d+)$/
        self.class_eval %Q{
          def #{field}
            @#{field}
          end
          def #{field}=(data)
            @#{field} = data.to_s
          end
        }
      elsif type < Nwdiy::Packet
        self.class_eval %Q{
          attr_reader :#{field}
          def #{field}=(data)
            data = #{type}.new(data) unless data.kind_of?(#{type})
            @#{field} = data
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
        self.__send__("#{var}=", val)
      end
    when String
      list = data.unpack(@@template[self.class] + "a*")
      @@fields[self.class].each do |cf|
        cls, field = cf
        if cls.kind_of?(Symbol)
          self.__send__("#{field}=", list.shift)
        elsif cls < Nwdiy::Packet
          self.__send__("#{field}=", cls.new(list.shift))
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
