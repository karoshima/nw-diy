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
        klass = NwDiy::IpLink.new[arg] ? NwDiy::Interface::Pcap : NwDiy::Interface::Sock
      end

      # 接続する
      begin
        @dev = klass.new(arg)
      rescue Errno::EPERM
        @dev = NwDiy::Interface::Proxy.new(klass, arg)
      end
    end

    ################
    # socket op
    def recv
      @dev.recv
    end
    def send(msg)
      @dev.send(msg)
    end
    def close
      @dev.close
    end
  end
end
