#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# ruby で綴る Virtual Machine

require_relative "interface"

class NWDIY
  class VM
    # いくつかのインターフェースを持つ VM を作る
    # in: インターフェースのリスト
    #     各インターフェースは以下いずれか
    #     { type: :pcap, name: "eth0" }: 実在リンクに pcap で送受信する
    #     { type: :tap,  name: "tap0" }: tap でリンクを作って送受信する
    #     { type: :file, name: <file> }: ソケットファイルを作って送受信する
    def initialize(ifp = [])
      @iflist = []
      self.newif(ifp)
    end
    def newif(ifp)
      # リストなら、リスト内の各インターフェースについて処理する
      ifp.kind_of?(Array) and
        return ifp.each {|ife| self.newif(ife)}

      # 単純文字列なら、ソケットファイルと認識する
      ifp.kind_of?(String) and
        return self.newif({type: :file, name: ifp})

      # Hash なら initialize の説明のとおり解釈する
      @iflist.push(NWDIY::IFP.create(ifp))
    end

    def iflist
      @iflist
    end
  end
end
