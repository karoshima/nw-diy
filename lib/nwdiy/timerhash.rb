#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# タイマー付き Hash

module NwDiy
  class TimerHash < Hash

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

    def initialize(*arg)
      super(*arg)

      # 省略時値
      @update     = true
      @oldvalue   = false
      @age        = 10
      @autodelete = true

      @period     = Hash.new    # エントリー毎の寿命データベース

      @lock = Thread::Mutex.new             # self と @period の...
      @cond = Thread::ConditionVariable.new # ...同期を取る
    end

    ################################################################
    # Hash インスタンスメソッドのオーバーライド

    ################
    # [] は寿命確認も行なう
    #    ageout したものは「無い」と見做す
    #    (ただし登録時に expired: :keep オプションを付けていた場合
    #     self.expired で取り出すまで内部には残る)
    alias :__super_get :[]
    def [](key)
      @lock.synchronize do
        self.__locked_get(key)
      end
    end
    def __locked_get(key)
      self.__locked_get_age(key) ? self.__super_get(key) : self.default
    end

    ################
    # []= もほぼ Hash のままだが、オプションで age も指定できる
    alias :__super_set :[]=
    def []=(key, age = @age, val)
      @lock.synchronize do
        self.__locked_set(key, age, val)
      end
    end
    def __locked_set(key, opt, val)
      old = self.__locked_get(key)
      self.__super_set(key, val)
      (@update || (old != val)) and
        self.__locked_set_age(key, age)
      return @oldvalue ? old : val
    end

    ################
    # delete は完全に Hash と同じ
    alias :__super_delete :delete
    def delete(key)
      @lock.synchronize do
        self.__locked_delete(key)
      end
    end
    def __locked_delete(key)
      @period.delete(key)
      self.__super_delete(key)
    end

    ################################################################
    # 寿命の管理

    ################
    # 時刻
    def self.uptime
      # 本来はシステム時刻の設定変更に惑わされないよう
      # uptime などを使いたいところ
      # 現在は手抜きで Time を使う
      Time.now.to_i
    end

    ################
    # 寿命の設定
    def set_age(key, age)
      @lock.synchronize do
        self.__locked_set_age(key, age)
      end
    end
    def reset_age(key)
      self.set_age(key, Float::INFINITY)
    end
    def __locked_set_age(key, age)
      if self.has_key?(key)
        @cond.signal
        @period[key] = self.class.uptime + age
        age
      end
    end

    ################
    # 余命の確認
    #    数値             残り時間
    #    Float::INFINITY  無限大
    #    nil              そもそもそんなキーは持っていない or 寿命が尽きている
    def get_age(key)
      @lock.synchronize do
        self.__locked_get_age(key)
      end
    end
    def __locked_get_age(key)
      if self.has_key?(key)
        remains = @period[key] - self.class.uptime
        (remains >= 0) and
          return remains
        @autodelete and
          self.__locked_delete(key)
        nil
      end
    end

    ################################################################
    # 寿命の監視
    #    :keep 属性のあるデータ限定

    ################
    # 掃除
    #    :keep 属性がなく expire しているデータを除く
    def __locked_swipe
      now = self.class.uptime
      self.select! {|key,val| @expiredb[key] == :keep || now <= @period[key] }
      nil
    end

    ################
    # 誰かが expire するまでの秒数
    #    既に expire しているデータがあるときは負値を返す
    def timeleft
      @lock.synchronize do
        self.__locked_timeleft
      end
    end
    def __locked_timeleft
      self.__locked_swipe
      @period.values.min - self.class.uptime
    end

    ################
    # 誰かが expire するまで待つ
    def wait_expire
      @lock.synchronize do
        loop do
          left = self.__locked_timeleft
          (left >= 0) or
            return 
          @cond.wait(@lock, left)
        end
      end
    end

    ################
    # expire したデータ群を Hash で返す
    def expired
      @lock.synchronize do
        self.__locked_expired
      end
    end
    def __locked_expired
      select.locked_swipe
      now = self.class.uptime
      self.select {|key,val| @period[key] < now }
    end

  end
end
