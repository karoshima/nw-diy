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
        @group = Hash.new { |hash,key| hash[key] = 0 }
        @group[0xe0000001] = 0x100000000 # almost infinity
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

    class IPv4
      attr_accessor :addr
      protected
      def addr_init(addr)
        @addr = IPv4AddrMask.new(addr)
      end
    end

    class IPv4AddrMask
      def initialize(addr)
        case addr
        when /^(\d+\.\d+\.\d+\.\d+)\/(\d+\.\d+\.\d+\.\d+)$/
          addr, mask = $1, $2
          @addr = Nwdiy::Packet::IPv4Addr.new(addr)
          @mask = Nwdiy::Packet::IPv4Addr.new(mask)
          @mlen = Nwdiy::Packet::IPv4addr::MLEN2MASK.find_index(@mask.addr)
        when /^(\d+\.\d+\.\d+\.\d+)\/(\d+)$/
          addr, mask = $1, $2
          @addr = Nwdiy::Packet::IPv4Addr.new(addr)
          @mask = Nwdiy::Packet::IPv4Addr.new(mask.to_i)
          @mlen = mask.to_i
        when /^(\d+\.\d+\.\d+\.\d+)$/
          @addr = Nwdiy::Packet::IPv4Addr.new(addr)
          if addr.classA?
            @mlen = 8
          elsif addr.classB?
            @mlen = 16
          elsif addr.classC?
            @mlen = 24
          else
            @mlen = 32
          end
            @mask = Nwdiy::Packet::IPv4Addr.new(mlen)
        else
          raise "unrecognized address \"#{addr}\""
        end
        @network = Nwdiy::Packet::IPv4Addr.new(@addr.addr & @mask.addr)
        @broadcast = Nwdiy::Packet::IPv4Addr.new(@addr.addr | (0xffffffff ^ @mask.addr))
      end

      def inspect
        "#{@addr.inspect}/#{@mlen}"
      end

      ALL0 = Nwdiy::Packet::IPv4Addr.new("0.0.0.0")
      ALLF = Nwdiy::Packet::IPv4Addr.new("255.255.255.255")

      def forme?(addr)
        return ALL0 == addr || ALLF == addr || 
               @addr == addr || @network == addr || @broadcast == addr
      end
    end

    class IPv4
      def join(group)
        unless group.kind_of?(Nwdiy::Packet::IPv4Addr)
          group = Nwdiy::Packet::IPv4Addr.new(group)
        end
        @group[group.addr] += 1
      end
      def leave(group)
        unless group.kind_of?(Nwdiy::Packet::IPv4Addr)
          group = Nwdiy::Packet::IPv4Addr.new(group)
        end
        @group[group.addr] -= 1
      end
      public
      def forme?(pkt)
        @addr.forme?(pkt.dst) || @group[pkt.dst.addr] > 0
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
