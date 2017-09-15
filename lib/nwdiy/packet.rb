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
  # サブクラスを定義する

  def self.def_field(type, name, option = {})

    raise TypeError.new("invalid field name '#{name}'") unless
      name.kind_of?(Symbol) || name.kind_of?(String)
    raise TypeError.new("invalid option '#{option}'") unless
      option.kind_of?(Hash)

    if type.kind_of?(Nwdiy::Packet)
      # サブクラスに読み書きメソッドを設定する
      self.class_eval %Q {
        def #{type}
          return @field_#{name} if @field_#{name}
          
        end
      }
    elsif method_defined?(type)
      
    end
  end

  ################################################################
  # サブクラス
  ################
  # @initbyte    生成時に指定されたバイト列
  # @field_###   def_field で設定されたフィールド値

  def initialize(value)
    case value
    when String
      # とりあえず @initbyte に覚えておいて
      # あとで必要に応じて参照する
      @initbyte = value
    when Hash
      # 各フィールドを設定する
      # 設定メソッドは def_field 内で定義する
      @@initbyte = nil
      value.each {|key,val| self.__send__(key.to_s+"=", val) }
    else
      TypeError.new("unsupported data `#{value}'")
    end
  end



    # @@cls_fields[self][name] に収めるハッシュを用意する
    field = [ index:  @@cls_fields[self].length,
              pos:    @@cls_bytelen[self],
              option: option ]
    if type.kind_of?(Nwdiy::Packet)
      field[:klass] = type
    elsif method_defined?(type)
      field[:method] = type
    else
      raise NoMethodError.new(cls)
    end
    @@cls_fields[self][name] = field
    @@cls_fields[self][(name.to_s + "=").to_sym] = name

    # パケットサイズ @@cls_bytelen[self] を更新する
    if field[:pos] && type.kind_of?(Nwdiy::Packet) && type.bytesize
      @@cls_bytelen[self] += type.bytesize
    else
      @@cls_bytelen[self] = nil
    end
  end



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
