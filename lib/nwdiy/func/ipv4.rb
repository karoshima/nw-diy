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
        self.arp_init(param[:arp])
        self.pktflow_init
        self.thread_init
      end
    end
    attr_accessor :arp

    # create an IPv4 instance from the lower layer
    # same as ethernet.rb

    module IPv4Receiver
      def ipv4(name=nil, **param)
        ipv4 = IPv4.new(name || (self.to_s + ":ipv4"), **param)
        ipv4.lower = self
        self[0x0800] = ipv4
        self[0x0806] = ipv4
        return ipv4
      end
    end

    class Ethernet
      include IPv4Receiver
      def ipv4(name = nil, **param)
        debug "eth.ipv4(#{name}, #{param})"
        param[:arp] = true
        super(name, **param)
      end
    end

    class IPv4
      public
      def lower=(instance)
        if instance
          debug "@instance_lower = #{instance}"
          @instance_lower = instance
          self.thread_start
        else
          self.thread_stop
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
      def joined?(group)
        unless group.kind_of?(Nwdiy::Packet::IPv4Addr)
          group = Nwdiy::Packet::IPv4Addr.new(group)
        end
        @group[group.addr] > 0
      end
      def leave(group)
        unless group.kind_of?(Nwdiy::Packet::IPv4Addr)
          group = Nwdiy::Packet::IPv4Addr.new(group)
        end
        @group[group.addr] -= 1 if self.joined?(group)

      end
      public
      def forme?(pkt)
        case pkt
        when Nwdiy::Packet::ARP
          @addr.forme?(pkt.ptgt)
        when Nwdiy::Packet::IPv4
          @addr.forme?(pkt.dst) || self.joined?(pkt.dst)
        else
          false
        end
      end
    end

    class IPv4
      ################################################################
      # Routing table
      def gateway(dst)
        return dst
      end

      ################################################################
      # ARP handler
      protected
      def arp_init(use_arp)
        @arp = use_arp ? Hash.new : nil
        @arp_mutex = Mutex.new
      end
      def arp_resolve(pkt)
        gw = gateway(pkt.dst)
        @arp_mutex.synchronize do
          now = Time.now
          if @arp.has_key?(gw.addr)
            arpentry = @arp[gw.addr]
            if now + 300 < arpentry[:time] && arpentry[:dst] != nil
              return Nwdiy::Packet::Ethernet.new(dst: arpentry[:dst],
                                                 data: pkt)
            end
          else
            @arp[gw.addr] = { time: now, dst: nil, packet: [] }
          end
          arp[gw.addr][:packet].push(pkt)
          arp = Nwdiy::Packet::ARP.request(gw, self.addr.addr, @instance_lower.addr)
          return Nwdiy::Packet::Ethernet.new(dst: "ff:ff:ff:ff:ff:ff",
                                             data: arp)
        end
      end
      def arp_recv(pkt)
        return unless self.forme?(pkt)
        case pkt.op
        when 1
          arp_recv_request(pkt)
        when 2
          arp_recv_response(pkt)
        else
          return
        end
      end
      def arp_recv_request(req)
        rsp = Nwdiy::Packet::ARP.response(pkt.psnd, pkt.hsnd, self.addr.addr, @instance_lower.addr)
        eth = Nwdiy::Packet::Ethernet.new(dst: pkt.hsnd, data: rsp)
        @instance_lower.sendpkt(eth)
      end
      def arp_recv_response(rsp)
        @arp_mutex.synchronize do
          debug "ARP response: #{@arp}"
          debug "ARP response: @arp[#{rsp.psnd.addr}]"
          debug "ARP response: @#{@arp[rsp.psnd.addr]}"
          if @arp.has_key?(rsp.psnd.addr) && @arp[rsp.psnd.addr][:dst] == nil
            arp = @arp[rsp.psnd.addr]
            arp[:dst] = rsp.hsnd
            que, arp[:packet] = arp[:packet], []
            que.each do |pkt|
              eth = Nwdiy::Packet::Ethernet.new(dst: arp[:dst], data: pkt)
              @instance_lower.sendpkt(eth)
            end
          end
        end
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

      ################
      # flow up
      #    flow up a packet from the lower layer instance
      public
      def push(pkt, lower=[])
        case pkt
        when Nwdiy::Packet::ARP
          arp_recv(pkt)
        when Nwdiy::Packet::IPv4
          ip_recv(pkt, lower)
        else
          raise Errno::EINVAL
        end
      end

      protected
      def ip_recv(pkt, lower)
        @upq_lower.push([pkt, lower])
      end

      def flowup
        pkt, lower = @upq_lower.pop
        debug pkt.inspect, lower
        upper = self.upper_for_packet(pkt)
        debug "#{self}.upper = #{upper.class}"
        if upper
          if self.forme?(pkt)
            debug "#{self}.upper = #{upper.class}"
            @stat[:rx] += 1
            upper.push(pkt.data, lower + [pkt])
          elsif upper.respond_to?(:push_others)
            debug #{self}.upper = #{upper.class}"
            @stat[:rx] += 1
            upper.push_others(pkt, lower)
          else
            debug #{self}.upper = #{upper.class}"
            @stat[:drop] += 1
          end
        else
          debug #{self}.upper = nil"
          @stat[:rx] += 1
          @upq_upper.push([pkt, lower])
        end
      end

      public
      def recvpkt
        @upq_upper.pop
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
        debug "pkt #{pkt.inspect} to #{lower}"
        unless lower
          return
        end
        if @arp
          pkt = arp_resolve(pkt)
        end
        lower.sendpkt(pkt)
      end
      def capsule(pkt)
        return pkt
      end

      public
      def pop
        @downq_upper.pop
      end

      ################################################################
      # upper layers
      def []=(type, func)
        @instance_upper[type] = func
      end
      def [](type)
        @instance_upper[type]
      end
      def upper_for_packet(pkt)
        debug pkt.class
        return nil unless pkt.kind_of?(Nwdiy::Packet::IPv4)
        debug "proto #{pkt.proto}"
        return self[pkt.proto]
      end
    end
  end
end
