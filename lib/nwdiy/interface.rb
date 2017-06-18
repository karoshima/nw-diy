#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# ruby で綴る VM interface
#
# インターフェース作成方法
# 
#  ifp = NwDiy::Interface.new(インターフェースの名称)
#    イーサネットフレームを送受信するためのインターフェース
#    インスタンスを作成します。
#    ただし、OS に実在するインターフェースの名称を指定した場合は
#    その実在するインターフェースから送受信しようとします。
#    実在しないインターフェースの名称を指定した場合には、
#    ソケットによる仮想的なインターフェースを利用します。
#
#  ifp = NwDIy::Interface.new(下記のハッシュ)
#                             name: インターフェースの名称
#                             type: :sock
#    同上
#
# 使いかた
#
#  ifp.recv
#    インターフェースでイーサネットフレームをひとつ受信して返します。
#    フレームが届いていなければ、届くまで待ちます。
#
#  ifp.ready?
#    インターフェースにイーサネットフレームが来ているかどうか返します。
# 
#  ifp.send
#    インターフェースからイーサネットフレームをひとつ送信します
#
################################################################

require_relative '../nwdiy'

require 'socket'

require 'nwdiy/iplink'
require 'nwdiy/interface/pcap'
require 'nwdiy/interface/sock'
require 'nwdiy/interface/proxy'

module NwDiy
  ################################################################
  # インターフェース
  class Interface
    @@debug = Hash.new
    def self.debug(hash = nil)
      if hash.kind_of?(Hash)
        @@debug.merge!(hash)
      end
      @@debug
    end
    def debug(*arg)
      self.class.debug(arg)
    end

    ################
    # new 引数はインターフェース名、あるいは情報付与したハッシュ
    def initialize(arg)
      raise ArgumentError.new("no interface: (nil)") unless arg

      # インターフェース種別 klass を決める
      if arg.kind_of?(Hash)
        case arg[:type]
        when :pcap
          klass = NwDiy::Interface::Pcap
        when :sock
          klass = NwDiy::Interface::Sock
        else
          raise ArgumentError.new("unknown interface type: #{arg[:type]}")
        end
        arg = arg[:name]
      end

      # ifindex あるいは ifname を決める
      case arg
      when Integer, String, NwDiy::IpLink::IfAddr
        # do nothing
      else
        if arg.respond_to?(:to_i) && arg.to_i > 0
          arg = arg.to_i
        elsif arg.respond_to?(:to_s) && arg.to_s != ''
          arg = arg.to_s
        else
          raise ArgumentError.new("unknown interface name: #{arg}");
        end
      end

      # 実在するか否かで klass を決める
      unless klass
        klass = NwDiy::Interface::Sock
        begin
          if NwDiy::IpLink.new[arg]
            klass = NwDiy::Interface::Pcap
          end
        rescue Errno::ENOENT
        end
      end

      # 接続する
      begin
        @dev = klass.new(arg)
      rescue Errno::EPERM
        @dev = NwDiy::Interface::Proxy.new(klass, arg)
      end
    end

    ################
    # interface address
    def to_s
      @dev.to_s
    end

    ################
    # interface address
    def local(addr = nil)
      addr ? @local = addr : @local
    end

    ################
    # socket op
    def recv
      pkt = @dev.recv
      if @@debug[:packet]
        puts "Receive packet from #{self}"
      end
      pkt
    end
    def send(msg)
      if @@debug[:packet]
        print "Sending pacaket from #{self} ..."
      end
      len = @dev.send(msg)
      if @@debug[:packet]
        puts " done"
      end
      len
    end
    def close
      @dev.close
    end
    def recv_ready?(timeout=0)
      @dev.recv_ready?(timeout)
    end
  end
end
