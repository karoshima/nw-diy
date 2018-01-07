#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require "rbconfig"

class Nwdiy::Func::Swc::Ethernet < Nwdiy::Func::Swc

  AGE_DEFAULT = 600

  def initialize(name = nil)
    super(name)
    @macdb = Hash.new
    @age = AGE_DEFAULT
    @checker = nil
    @lock = Thread::Mutex.new
    @cond  = Thread::ConditionVariable.new
  end
  def self.class_name
    "ethernet_switch"
  end

  def on
    @macdb.clear
    @checker = Thread.start { self.check_age }
    return super
  end

  def off
    retval = super
    @checker.kill.join
    @checker = nil
    return retval
  end

  attr_reader :age
  def age=(newage)
    raise InvalidAgeError.new "age(#{newage}) must be Integer or Float" unless
      newage.kind_of?(Numeric)
    @age = newage
    @cond.broadcast
  end
  class InvalidAgeError < Exception; end

  # パケット中継するよ
  def forward(pkt)
    return nil unless pkt.kind_of?(Nwdiy::Packet::Ethernet)
    self.macdb_set(pkt.src, pkt.from)
    pkt.to = [self.macdb_get(pkt.dst)]
    pkt.to = self.attached unless pkt.to[0]
    pkt.to -= [pkt.from]
    return pkt
  end

  ################
  # 学習テーブル
  def macdb_set(mac, ifp)
    return nil unless mac.unicast?
    @lock.synchronize do
      entry = @macdb[mac.addr]
      if @macdb[mac.addr] == nil || @macdb[mac.addr][:ifp] != ifp
        @macdb[mac.addr] = { ifp: ifp, time: self.uptime }
        @cond.signal
      end
    end
  end
  def macdb_get(mac)
    return nil unless mac.unicast?
    @lock.synchronize do
      return @macdb[mac.addr] ? @macdb[mac.addr][:ifp] : nil
    end
  end

  # 学習テーブルの定期メンテ
  def check_age
    @lock.synchronize do
      now = self.uptime
      loop do
        limit = now - @age
        oldest = nil
        @macdb.keep_if do |mac, entry|
          if limit < entry[:time]
            oldest = entry[:time]
          else
            false
          end
        end
        if oldest
          oldest = oldest + @age - now
        end
        @cond.wait(@lock, oldest)
        now = self.uptime
      end
    end
  end

  case RbConfig::CONFIG["host_os"]
  when /linux/
    @@uptimeTime = Time.now
    @@uptimeVal = `cat /proc/uptime`.split[0].to_f
    def uptime
      if Time.now - @@uptimeTime > 0.05
        @@uptimeVal = `cat /proc/uptime`.split[0].to_f
      end
      @@uptimeVal
    end
  else
    def uptime
      Time.now.to_f # これは暫定措置で、時刻設定の影響を受けちゃいます
    end
  end

end
