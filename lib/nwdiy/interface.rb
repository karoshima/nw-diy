#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# ruby で綴る VM interface

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
      hash.kind_of?(Hash) and
        @@debug.merge!(hash)
      @@debug
    end
    def debug(*arg)
      self.class.debug(arg)
    end

    ################
    # new 引数はインターフェース名、あるいは情報付与したハッシュ
    def initialize(arg)
      arg or
        raise ArgumentError.new("no interface: (nil)");

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
        if arg.respond_to?(:to_i) and arg.to_i > 0
          arg = arg.to_i
        elsif arg.respond_to?(:to_s) and arg.to_s != ''
          arg = arg.to_s
        else
          raise ArgumentError.new("unknown interface name: #{arg}");
        end
      end

      # 実在するか否かで klass を決める
      unless klass
        klass = NwDiy::Interface::Sock
        begin
          NwDiy::IpLink.new[arg] and
            klass = NwDiy::Interface::Pcap
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
      @@debug[:packet] and
        puts "Receive packet from #{self}"
      pkt
    end
    def send(msg)
      @@debug[:packet] and
        print "Sending pacaket from #{self} ..."
      len = @dev.send(msg)
      @@debug[:packet] and
        puts " done"
      len
    end
    def close
      @dev.close
    end
    def recvq_empty?
      @dev.recvq_empty? ? true : false
    end
  end
end
