#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# ruby で綴る Virtual Machine
# 
# これは L2Switch など様々な VM を作成するときに
# 親クラスとして使用します。
# 
# vm = NwDiy::VM.new(インターフェース名あるいはインターフェース
#                    インスタンスのリスト)
#    接続するインターフェースを指定して VM を作成します。
# 
# vm.iflist
#    インターフェース一覧を返します
# 
# vm.addif(インターフェースあるいはインターフェースのリスト)
#    インターフェースを追加します。
#
# vm.delif(インターフェースあるいはインターフェースのリスト)
#    インターフェースを削除します。
#
# vm.recv
#    登録してあるインターフェースいずれかで
#    イーサネットフレームをひとつ受信して返します。
#    フレームが届いてなければ、届くまで待ちます。
# 
################################################################

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
      return ifp[:name] if ifp.kind_of?(Hash)
      return ifp.to_s if ifp.kind_of?(NwDiy::Interface)
      return ifp
    end

    def addif(ifp)
      # リストなら、リスト内の各インターフェースについて処理する
      if ifp.kind_of?(Array)
        return ifp.map {|ifp2| self.addif(ifp2)}
      end

      # インターフェース名→インターフェース種別ハッシュ
      name = ifname(ifp)
      if @ifs[name]
        raise Errno::EEXIST.new("interface #{ifp} already exists")
      end
      unless ifp.kind_of?(NwDiy::Interface)
        ifp = NwDiy::Interface.new(ifp)
      end
      @ifs[name] = ifp
      @threads[name] = Thread.new(ifp) do |ifp2|
        begin
          loop do
            @pktqueue.push([ifp2, ifp2.recv])
          end
        ensure
          # kill されても静かに終了する
        end
      end
      @ifs[name]
    end

    def delif(ifp)
      # リストなら、リスト内の各インターフェースについて処理する
      if ifp.kind_of?(Array)
        return ifp.map {|ifp2| self.delif(ifp2)}
      end

      name = ifname(ifp)
      unless @ifs[name]
        raise Errno::ENOENT.new("interfacd #{ifp} does not exist")
      end

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
