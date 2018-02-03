#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

class Nwdiy::Func::Swc < Nwdiy::Func

  autoload(:Ethernet, 'nwdiy/func/swc/ethernet')

  attr_accessor :attached

  @@swc_index = 0
  def initialize(name = nil)
    super(name)
    @interfaces = Hash.new
  end
  def class_name
    "swc"
  end

  def on
    super
    @interfaces.each_key do |ifp|
      next if @interfaces[ifp]
      @interfaces[ifp] = self.thread_start(ifp)
    end
    true
  end

  def off
    super
    @interfaces.each_value {|t| t.kill }
    @interfaces.transform_values {|t| t.join; nil }
    false
  end

  def attach(ifp)
    raise NotInterfaceError.new "attach(#{ifp}(#{ifp.class})) requires Nwdiy::Func::Ifp instance)" unless ifp.kind_of?(Nwdiy::Func::Ifp)
    if self.power
      unless @interface[ifp].kind_of?(Thread)
        @interface[ifp] = self.thread_start(ifp)
      end
    else
      @interfaces[ifp] = nil
    end
    self
  end
  alias :attach_left  :attach
  alias :attach_right :attach

  def attached
    @interfaces.keys
  end

  def detach(ifp)
    thr = @interfaces.delete(ifp)
    if thr.kind_of?(Thread)
      thr.kill.join
    end
    return ifp
  end

  def thread_start(ifp)
    Thread.new(ifp) do |src|
      loop do
        # パケットひとつ受信する
        inpkt = src.recv
        inpkt.from = src
        inpkt.to = nil

        # Swc の子クラスに定義した forward メソッドで
        # 受信したパケットを処理する
        *outpkts = self.forward(inpkt)

        # 処理したパケットを複製して送信する
        outpkts.each do |outpkt|
          next unless outpkt
          ifp = outpkt.to
          outpkt.from = nil
          outpkt.to = nil
          case ifp
          when Nwdiy::Func::Ifp
            ifp.send(Marshal.load(Marshal.dump(outpkt)))
          when Array
            ifp.each do |ifpp| 
              ifpp.send(Marshal.load(Marshal.dump(outpkt))) if 
                ifpp.kind_of?(Nwdiy::Func::Ifp)
            end
          end
        end
      end
    end
  end

  # エラー
  class NotInterfaceError; end  # インターフェースを指定してください
end
