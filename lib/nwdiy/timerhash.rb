#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# タイマー付き Hash

module NwDiy
  class TimerHash < Hash

    def initialize(*arg)
      super(*arg)
      @age = nil                             # デフォルト寿命値
      @period = Hash.new                     # expire予定時刻の管理
      @lock = Thread::Mutex.new              # self と @period の...
      @cond = Thread::ConditionVariable.new   # ...同期を取る
    end

    ################################################################
    # グローバル設定 - 寿命
    attr_accessor :age

    ################################################################
    # 寿命の設定
    def set_age(key, age = @age)
      owned = false
      begin
        @lock.lock
      rescue ThreadError
        owned = true
      end
      if self.has_key?(key)
        if age
          ret = @period[key] = self.uptime + age
        else
          @period.delete(key)
          ret = nil
        end
        @cond.signal
      else
        ret = nil
      end
      owned or
        @lock.unlock
      ret
    end
    def reset_age(key)
      self.set_age(key, nil)
    end
    
    def uptime
      File.open('/proc/uptime') do |proc|
        return proc.gets.to_f
      end
    end

    ################################################################
    # self に対する処理
    ################
    def __valid?(key)
      @lock.locked? or
        raise "NOT LOCKED"
      (self.has_key?(key) && !self.expired?(key))
    end
    # ほぼ []= や store だが、
    # 寿命を設定するとともに
    # 上書きされてしまった旧値を返す
    def overwrite(key, val, update = false, age = @age)
      old = nil
      @lock.synchronize do
        update |= !self.__valid?(key)
        old = self[key]
        self[key] = val
        update and
          self.set_age(key, age)
      end
      old
    end
    ################
    # ほぼ [] だが、expire していたら nil を返す
    def value(key)
      @lock.synchronize do
        self.__valid?(key) ? self[key] : nil
      end
    end

    ################################################################
    # 寿命の監視
    ################
    # (keyのエントリー or 誰か) が expire するまでの秒数
    def timeleft(key = nil)
      min = key ? @period[key] : @period.values.min
      min ? min - self.uptime : nil
    end
    # (keyのエントリー or 誰か) が expire しているか？
    def expired?(key = nil)
      left = self.timeleft(key)
      !(left && left > 0)
    end
    # 誰かが expire するまで待つ
    def wait_expire
      @lock.synchronize do
        loop do
          @cond.wait(@lock, self.timeleft)
          self.expired? and
            return
        end
      end
    end

    ################################################################
    # 寿命エントリーの操作
    ################
    # expired したものだけを選別した新しいハッシュを返す
    def each_expired
      @lock.synchronize do
        now = self.uptime
        expired = self.select {|key,val| self.expired?(key) }
      end
      expired
    end
    # expired したものを削除して、削除したものハッシュを返す
    def delete_expired
      @lock.synchronize do
        now = self.uptime
        expired = self.select {|key,val| self.expired?(key) }
        self.reject! {|key,val| self.expired?(key) }
        expired.key.each {|key| @period.delete(key) }
      end
      expired
    end
  end
end
