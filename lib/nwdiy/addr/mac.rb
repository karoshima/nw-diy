#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# Nwdiy::Addr::Mac は MAC アドレスです
#
# new 時に以下の引数を与えることができます。
#
# - 6byte のデータ
#    バイナリデータとして解釈します。
#
# - Nwdiy::Addr::Mac インスタンス
#    内容をコピーします
#
# - :global
#    乱数ベースでグローバルな MAC アドレスを作ります。
#
# - :local
#    乱数ベースでローカルな MAC アドレスを作ります。
#
# - 文字列
#    MAC アドレスフォーマットだろうとして頑張って解釈してみます。
#
# インスタンスには下記のメソッドがあります。
#
# - unicast?    ユニキャストアドレスであれば true を返します
# - multicast?  マルチキャストであれば true を返します。
# - broadcast?  ブロードキャストであれば true を返します。
# - global?     グローバルアドレスであれば true を返します。
# - local?      ローカルアドレスであれば true を返します。
################################################################

require "nwdiy/addr"

class Nwdiy::Addr::Mac
  include Nwdiy::Addr

  def initialize(mac = nil)
    case mac
    when self.class
      @addr = mac.addr.dup
    when :global
      @addr = [0] + (1..5).map { rand(256) }
    when :local  
      @addr = [2] + (1..5).map { rand(256) }
    when String
      if mac.bytesize == 6
        @addr = mac.unpack("C6")
      else
        match = /^(\h\h?):(\h\h?):(\h\h?):(\h\h?):(\h\h?):(\h\h?)$/.match(mac)
        match = /^(\h\h?)-(\h\h?)-(\h\h?)-(\h\h?)-(\h\h?)-(\h\h?)$/.match(mac) unless match
        match = /^(\h\h?)\.(\h\h?)\.(\h\h?)\.(\h\h?)\.(\h\h?)\.(\h\h?)$/.match(mac) unless match
        raise Invalid.new("invalid MAC addr: #{addr}") unless match
        @addr = match[1..6].dup
      end
    else
      @addr = [0, 0, 0, 0, 0, 0]
    end
  end

  attr_accessor :addr

  # アドレスをバイナリ化します
  def to_s
    @addr.pack("C6")
  end

  # アドレスを可視化します
  def inspect
    @addr.map {|byte| sprintf("%02x", byte) }.join(":")
  end

  # アドレス種別を返します
  def unicast?
    (@addr[0] & 0x01) == 0
  end
  def multicast?
    !unicast?
  end
  def broadcast?
    @addr == [255, 255, 255, 255, 255, 255]
  end
  def global?
    (@addr[0] & 0x02) == 0
  end
  def local?
    !global?
  end

  def hash
    @addr.inject(0) { |hash, byte| (hash * 0x100) + byte.to_i }
  end
  def eql?(obj)
    case obj
    when Nwdiy::Addr::Mac
      return self.hash == obj.hash
    when String
      return self.hash == Nwdiy::Addr::Mac.new(obj).hash
    end
  end
  alias == eql?

end
