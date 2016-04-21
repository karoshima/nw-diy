#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# ruby で綴る Virtual Machine

require_relative '../nwdiy'

require 'nwdiy/iplink'
require 'nwdiy/interface'

class NwDiy
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

      # 単純文字列なら、インターフェース名と見做す
      if (ifp.kind_of?(String))
        @iflist.index(ifp) and raise Errno::EEXIST.new("interface #{ifp} already exists.");
        ifp = { name: ifp, type: (NwDiy::IpLink.new[ifp] ? :pcap : :sock) }
      end

      @iflist.push(NwDiy::Interface.new(ifp))
    end

    def iflist
      @iflist
    end
  end
end

#class DuplicateInterface < Exception
#end
