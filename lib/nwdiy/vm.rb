#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# ruby で綴る Virtual Machine

require_relative '../nwdiy'

require 'nwdiy/iplink'
require 'nwdiy/interface'

module NwDiy
  class VM
    # いくつかのインターフェースを持つ VM を作る
    # in: インターフェースのリスト
    #     各インターフェースは以下いずれか
    #     { type: :pcap, name: "eth0" }: 実在リンクに pcap で送受信する
    #     { type: :tap,  name: "tap0" }: tap でリンクを作って送受信する
    #     { type: :file, name: <file> }: ソケットファイルを作って送受信する
    def initialize(*ifp)
      @ifs = Hash.new
      @threads = Hash.new
      @pktqueue = SizedQueue.new(64)
      self.addif(ifp)
    end

    def ifname(ifp)
      ifp.kind_of?(Hash) and
        return ifp[:name]
      ifp.kind_of?(NwDiy::Interface) and
        return ifp.to_s
      ifp
    end

    def addif(ifp)
      # リストなら、リスト内の各インターフェースについて処理する
      ifp.kind_of?(Array) and
        return ifp.each {|ifp2| self.addif(ifp2)}

      # インターフェース名→インターフェース種別ハッシュ
      name = ifname(ifp)
      @ifs[name] and
        raise Errno::EEXIST.new("interface #{ifp} already exists")

      nwif = NwDiy::Interface.new(ifp)
      @ifs[name] = nwif
      @threads[name] = Thread.new(nwif) do |nwif2|
        begin
          loop do
            @pktqueue.push([nwif2, nwif2.recv])
          end
        ensure
          # kill されても静かに終了する
        end
      end
    end

    def delif(ifp)
      # リストなら、リスト内の各インターフェースについて処理する
      ifp.kind_of?(Array) and
        return ifp.each {|ifp2| self.delif(ifp2)}

      name = ifname(ifp)
      @ifs[name] or
        raise Errno::ENOENT.new("interfacd #{ifp} does not exist")

      @threads[name].kill.join
      @threads.delete(name)
      @ifs.delete(name)
    end

    def iflist
      @ifs.values
    end
    def ifp(name)
      @ifs[name]
    end

    def recv
      @pktqueue.pop
    end
  end
end

#class DuplicateInterface < Exception
#end
