#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2018 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# with Apache-2 license.  check /LICENSE please.
################################################################
# Nwdiy::Func::IPv4
#    IPv4 interface class
# Nwdiy::Func::IPv4Receiver
#    instance method for instances under Nwdiy::Func::IPv4
################################################################

module Nwdiy
  module Func
    class IPv4

      include Nwdiy::Func
      include Nwdiy::Debug

      def initialize(name, **param)
        super(name)
        self.addr_init(param[:local])
      end
    end

    # create an IPv4 instance from the lower layer
    # same as ethernet.rb

    module IPv4Receiver
      def ipv4(name=nil, **param)
        ipv4 = IPv4.new(name || (self.to_s + ":ipv4"), **param)
        ipv4.lower = self
        return ipv4
      end
    end

    class Ethernet
      include IPv4Receiver
    end

    class IPv4
      public
      def lower=(instance)
        if instance
          @instance_lower = instance
        else
          @instance_lower = nil
        end
      end
    end

    ################################################################
    # IPv4 address configuration

    attr_reader :addr, :mask

    protected
    def addr_init(addr)
      puts addr
      case addr
      when /^(\d+\.\d+\.\d+\.\d+)\/(\d+\.\d+\.\d+\.\d+)$/
        addr, mask = $1, $2
        @addr = Nwdiy::Packet::IPv4Addr.new(addr)
        @mask = Nwdiy::Packet::IPv4Addr.new(mask)
      when /^(\d+\.\d+\.\d+\.\d+)\/(\d+)$/
        addr, mask = $1, $2
        @addr = Nwdiy::Packet::IPv4Addr.new(addr)
        @mask = Nwdiy::Packet::IPv4Addr.new(mask.to_i)
      when /^(\d+\.\d+\.\d+\.\d+)$/
        @addr = Nwdiy::Packet::IPv4Addr.new(addr)
        @mask = Nwdiy::Packet::IPv4Addr(addr.classA? ? 8 :
                                         addr.classB? ? 16 :
                                           addr.classC? ? 24 : 32)
      else
        raise "unrecognized address \"#{addr}\""
      end
    end

    class IPv4
      def sendpkt(pkt)
      end
      def recvpkt
      end
    end
  end
end
