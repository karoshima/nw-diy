#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# タイマー付き Hash

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
        @data[key] or
          return nil
        self.class.uptime <= @data[key][:expire] and
          return @data[key][:value]
        @autodelete and
          @data.delete(key)
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
        @data[key] or
          return nil
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
      @lock.locked? or raise "NOT LOCKED"
      uptime = self.class.uptime
      left = Float::INFINITY
      alive = Hash.new
      expired = Hash.new
      @data.each do |key,struct|
        remains = struct[:expire] - uptime
        if remains >= 0
          remains < left and
            left = remains
          alive[key] = struct[:value]
        else
          expired[key] = struct[:value]
        end
      end
      @autodelete or
        expired = Hash.new
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
          expired.length > 0 and
            return expired
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
