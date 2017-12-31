#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

class Nwdiy::Func::Flt < Nwdiy::Func

  attr_accessor :attached
  def initialize
    @attached = [ nil, nil ]
    @threads = [ nil, nil ]
  end

  def on
    super
    @threads[0] = self.thread_start(0, 1)
    @threads[1] = self.thread_start(1, 0)
  end

  def off
    @threads.map!{|t| t.kill }.map!{|t| t.join; nil }
  end

  def attach_left(ifp)
    self.attach_index(0, ifp)
  end
  def attach_right(ifp)
    self.attach_index(1, ifp)
  end
  def detach_left
    self.attach_index(0, nil)
  end
  def detach_right
    self.attach_index(1, nil)
  end

  def attach_index(index, ifp)
    return ifp if @attached[index] == ifp
    old = @attached[index]
    if old
      @threads[index].kill.join
      @threads[index] = nil
    end
    @attached[index] = ifp
    @threads[index] = self.thread_start(index, 1-index)
    return old
  end

  def thread_start(src, dst)
    return nil unless @attached[src]
    Thread.new(src, dst) do |sss, ddd|
      loop do
         # パケットひとつ受信する
        inpkt = @attached[sss].recv
        inpkt.from = @attached[sss]
        inpkt.to = @attached[ddd]

        # Flt の子クラスに定義した forward メソッドで
        # 受信したパケットを処理する
        *outpkts = self.forward(inpkt)

        # 処理したパケットを送信する
        outpkts.each do |outpkt|
          if outpkt && outpkt.to
            outpkt.to.send(outpkt)
          end
        end
      end
    end
  end

end
