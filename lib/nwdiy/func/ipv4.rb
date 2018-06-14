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
        self.pktflow_init
        self.thread_init
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
        @group = Hash.new { |hash,key| hash[key] = 0 }
        @group[0xe0000001] = 0x100000000 # almost infinity
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

      attr_accessor :addr
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

    ################################################################
    # packet handler

    class IPv4
      protected
      def pktflow_init
        @instance_upper = Array.new
        @instance_lower = nil
        @stat = Hash.new { |hash,key| hash[key] = 0 }
        @upq_upper = Nwdiy::Func::PktQueue.new
        @upq_lower = Nwdiy::Func::PktQueue.new
        @downq_upper = Nwdiy::Func::PktQueue.new
      end

      ################
      # flow up
      #    flow up a packet from the lower layer instance
      public
      def recvpkt
      end

      protected
      def flowup
      end

      ################
      # flow down
      #    flow down a packet from the upper layer instance
      public
      def sendpkt(dst=nil, pkt)
        @stat[:tx] += 1

        debug "#{self.to_s}.sendpkt(#{pkt.inspect})"

        unless pkt.kind_of?(Nwdiy::Packet::IPv4)
          pkt = Nwdiy::Packet::IPv4.new(dst: dst, data: pkt)
        end
        if pkt.src == "0.0.0.0" and @addr != nil
          pkt.src = @addr.addr
        end

        # do not flow down the packet for me
        if self.forme?(pkt)
          debug "#{self.to_s}.upq_lower.push([#{pkt.inspect}, []])"
          @upq_lower.push([pkt, []])
        else
          debug "#{self.to_s}.downq_upper.push(#{pkt.inspect})"
          @downq_upper.push(pkt)
        end
        return pkt.bytesize
      end

      protected
      def flowdown
        pkt = @downq_upper.pop
        pkt = self.capsule(pkt)
        lower = @instance_lower
        if lower
          lower.sendpkt(pkt)
        end
      end
      def capsule(pkt)
        return pkt
      end

      public
      def pop
        @downq_upper.pop
      end

      ################################################################
      # internal threads
      protected
      def thread_init
        # threads that flow the packet up & down
        @thread_flowup = Thread.new do
          loop do
            self.flowup
          end
        end
        @thread_flowdown = nil
      end

      def thread_start
        debug "#{self.to_s}.thread_start"
        @thread_flowdown = Thread.new do
          debug "#{self.to_s}.@thread_flowdown start"
          loop do
            self.flowdown
          end
        end
      end

      def thread_stop
        debug "#{self.to_s}.thread_stop"
        @thread_flowdown.kill.join if @thread_flowdown
        @thread_flowdown = nil
      end

      public
      def thread_stopall
        @thread_flowdown.kill if @thread_flowdown
        @thread_flowup.kill   if @thread_flowup
        @thread_flowdown.join if @thread_flowdown
        @thread_flowup.join   if @thread_flowup
        @thread_flowdown = nil
        @thread_flowup = nil
      end

    end
  end
end
