#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# タイマー付き Hash
#
# hash = NwDiy::TimerHash.new(opt = {})
#    データ毎にタイマーを持つ Hash を作成します。
#    opt として以下の指定ができます。
#      { update: 真偽値 }   参照されたら寿命をリフレッシュします (省略時値: 真)
#      { oldvalue: 真偽値 } 上書き時に旧データを返します (省略時値: 偽)
#      { age: 寿命(秒) }    データの寿命を指定します (省略時値: 無限大)
#      { autodelete: 真偽 } 寿命を迎えたとき自動で削除します (省略時値: 真)
# 
# hash[key, age] = value
#    hash[key] = value としてデータを登録します。
#    このデータの寿命は age になります。
#    age は省略可能であり、省略すると new 時に opt で指定した age を使います。
#
# hash[key]
#    データが寿命を迎えていなければ、Hash と同様に value を参照します。
#    寿命を迎えている場合、nil を返します。
#
# hash.delete(key)
#    データを削除します。
#
# hash.set_age(key, age)
#    データの寿命を更新します。
#
# hash.get_age(key)
#    データの余命を返します。
#
# hash.expired
#    既に寿命を迎えているデータを返します。
#    new 時のオプションで autodelete が偽のときに機能します。
# 
# hash.wait_expired
#    データのうちのひとつが寿命を迎えるまで待って、
#    寿命を迎えたデータを返します。
#    new 時のオプションで autodelete が偽のときに機能します。
#
################################################################

require_relative '../nwdiy'

module NwDiy
  class TimerHash < Enumerator

    ################
    # 追加時に寿命を更新する(true)か否(false)か
    attr_accessor :update

    ################
    # 登録時に旧値を得る(true)か否(false)か
    attr_accessor :oldvalue

    ################
    # デフォルト寿命
    attr_accessor :age

    ################
    # 寿命が尽きたときの挙動
    #    true   勝手に削除
    #    false  self.[] では見えないが self.expired で取得するまで内部に残す
    attr_accessor :autodelete

    def initialize(opt = {})

      # 省略時値
      @update     = opt.has_key?(:update)     ? opt[:update]     : true
      @oldvalue   = opt.has_key?(:oldvalue)   ? opt[:oldvalue]   : false
      @age        = opt.has_key?(:age)        ? opt[:age]      : Float::INFINITY
      @autodelete = opt.has_key?(:autodelete) ? opt[:autodelete] : true

      @lock = Thread::Mutex.new
      @cond = Thread::ConditionVariable.new

      ################
      # データベース本体
      #    @data[key] = { value: 値, expire: タイムアウト時刻 }
      @data       = Hash.new

    end

    ################################################################
    # データ管理

    ################
    # Hash と同様に []= で設定する
    #    ただし [] 内に第2引数として寿命オプションを指定できる
    #    寿命オプションがなければ、この Hash に指定した @age を使う
    def []=(key, age = @age, value)
      @lock.synchronize do
        begin
          uptime = self.class.uptime
          if @data[key] && uptime <= @data[key][:expire]
            if @data[key][:value] == value
              if @update
                @data[key][:expire] = uptime + age
              end
              return value
            end
            old = @data[key]
            @data[key] = { value: value, expire: uptime + age }
            return @oldvalue ? old[:value] : value
          end
          @data[key] = { value: value, expire: uptime + age }
          return @oldvalue ? nil : value
        ensure
          @cond.broadcast
        end
      end
    end

    ################
    # Hash と同様に [] で参照する
    def [](key)
      @lock.synchronize do
        return nil unless @data[key]
        return @data[key][:value] if self.class.uptime <= @data[key][:expire]
        @data.delete(key) if @autodelete
        return nil
      end
    end

    ################
    # Hash と同様に delete でデータ削除
    def delete(key)
      @lock.synchronize do
        old = @data.delete(key)
        return (old && self.class.uptime <= old[:expire]) ? old[:value] : nil
      end
    end

    ################################################################
    # 寿命管理

    ################
    # 現在時刻
    def self.uptime
      # 本来はシステム時刻の設定変更に惑わされないよう
      # uptime などを使いたいところ
      # 現在は手抜きで Time を使う
      Time.now.to_i
    end

    ################
    # 寿命の変更
    def set_age(key, age)
      @lock.synchronize do
        if @data[key]
          uptime = self.class.uptime
          if uptime <= @data[key][:expire]
            @data[key][:expire] = uptime + age
          elsif @autodelete
            @data.delete(key)
          end
        end
      end
    end

    ################
    # 残り時間の確認
    #    数値             残り時間(秒)
    #    Float::INFINITY  無限大
    #    nil              そもそもそんなキーは持っていない or 寿命が尽きている
    def get_age(key)
      @lock.synchronize do
        return nil unless @data[key]
        remains = @data[key][:expire] - self.class.uptime
        return remains >= 0 ? remains : nil
      end
    end

    private
    ################
    # expire したデータを掃除して、以下の 2 値を返す
    # 1. 次の掃除までの時間
    # 2. 有効なデータ
    # 3. 掃除されたデータ
    def _scan
      raise "NOT LOCKED" unless @lock.locked?
      uptime = self.class.uptime
      left = Float::INFINITY
      alive = Hash.new
      expired = Hash.new
      @data.each do |key,struct|
        remains = struct[:expire] - uptime
        if remains >= 0
          if remains < left
            left = remains
          end
          alive[key] = struct[:value]
        else
          expired[key] = struct[:value]
        end
      end
      expired = Hash.new unless @autodelete
      return [left, alive, expired]
    end

    public
    ################
    # 既に expire しているデータを抜き出して
    # Hash 化して返す
    def expired
      @lock.synchronize do
        left, alive, expired = _scan
        return expired
      end
    end

    ################
    # ひとつ以上のデータが expire するのを待って、
    # expire したデータを Hash 化して返す
    def wait_expired
      @lock.synchronize do
        loop do
          left, alive, expired = _scan
          return expired if expired.length > 0
          @cond.wait(@lock, left)
        end
      end
    end

    ################
    # expire してないものを抜き出して each する
    def each
      alive = nil
      @lock.synchronize do
        left, alive, expired = _scan
      end
      alive.each {|key,value| yield(key, value) }
    end
  end
end
