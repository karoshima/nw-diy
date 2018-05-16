#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2018 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# with Apache-2 license.  check /LICENSE please.
################################################################
# Nwdiy::Func::Ethernet
#    Ethernet interface class
# Nwdiy::Func::EthernetReceiver
#    instance methods for intances under Nwdiy::Func::Ethernet
################################################################
# Nwdiy::Func::Ethernet
# Ethernet interface
#
# You can send/recv a packet with this instance.
#
# pkt, lower = eth.recv()
#    You can get a packet received with this Ethernet instance.
#    If you have an upper layer instance such as eth.ip,
#    you can get IP packet from the ip instance (not on the eth instance).
#    return value "lower" is the lower layer header array.
#
# eth.send(dst=nil, pkt)
#    1. You can send an Ethernet frame.
#       In this case, you must fill all of the Ethernet fields.
#       (you can get the instance MAC address via "eth.addr")
#    2. You can send an L3 frame.
#       In this case, you must say "dst" mac address.
#
# You can create an ethernet driver.
#
# eth.push(pkt, lower=[])
#    You can push an Ethernet frame.
#    If the packet has the underlying headers, you should set it
#    in "lower" arg.
#
# pkt = eth.pop
#    You can get an Ethernet frame which is registered to be sent
#    from this Ethernet instance.
#
################################################################

require 'thread'

module Nwdiy
  module Func

    ################################################################
    # create an Ethernet instance

    class Ethernet

      include Nwdiy::Func
      include Nwdiy::Debug

      def initialize(name)
        super(name)

        self.addr_init
        self.pktflow_init
        self.thread_init

      end
    end

    # create an Ethernet instance from the lower layer
    #
    # class of lower instance (which includel EthernetReceiver) should
    # override the public method "ethernet" to save the instance
    #
    # for example: save the instance to a instance_variable.
    # def ethernet
    #   @eth = super
    #   return 
    # end

    module EthernetReceiver
      def ethernet
        eth = Ethernet.new(self.to_s + ":eth")
        eth.lower = self
        return eth
      end
    end

    class Ethernet
      public
      def lower=(instance)
        debug "#{self.to_s}.lower = #{instance.to_s}"
        if instance
          @instance_lower = instance
          self.thread_start
        else
          self.thread_stop
          @instance_lower = nil
        end
      end
      def lower
        @instance_lower
      end
    end

    class Ethernet

      # close the instance
      public
      def close
        self.thread_stopall
        self.close_lower
      end
      protected
      def close_lower
        if @instance_lower
          @instance_lower = nil
        end
      end

      ################################################################
      # MAC address configuration

      protected
      def addr_init
        # my address
        @addr = self.addr_default
        # my joined group addresses
        @join = Hash.new
      end
      def addr_default
        Nwdiy::Packet::MacAddr.new(:global)
      end

      public
      # unicast MAC address
      def addr=(mac)
        if mac == nil
          @addr = nil
        else
          @addr = Nwdiy::Packet::MacAddr.new(mac)
        end
      end
      attr_reader :addr

      # multicast MAC group addresses
      def join(group = nil)
        if group != nil
          raise Errno::EINVAL unless group.kind_of?(Nwdiy::Packet::MacAddr)
          raise Errno::EINVAL unless group.multicast?
          raise Errno::EINVAL if     group.broadcast?
          @join[group] = true
        end
        return @join
      end
      def forme?(pkt)
        pkt.dst == @addr || @join[pkt.dst]
      end
      def leave(group)
        @join.delete(group)
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
      def thread_stopall
        @thread_flowdown.kill if @thread_flowdown
        @thread_flowup.kill   if @thread_flowup
        @thread_flowdown.join if @thread_flowdown
        @thread_flowup.join   if @thread_flowup
        @thread_flowdown = nil
        @thread_flowup   = nil
      end
    end

    ################################################################
    # packet flow
    class Ethernet
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
      #    up a packet from the lower layer instance

      public 
      def push(pkt, lower=[])
        raise Errno::EINVAL unless pkt.kind_of?(Nwdiy::Packet::Ethernet)
        @upq_lower.push([pkt, lower])
      end

      # flow up the incoming packets
      protected
      def flowup
        pkt, lower = @upq_lower.pop
        # check the upper layer to pass
        upper = self.upper_for_packet(pkt)
        debug "#{self}.upper = #{upper.class}"
        if upper
          if self.forme?(pkt)
            debug "#{self}.upper = #{upper.class}"
            @stat[:rx] += 1
            upper.push(pkt.data, lower + [pkt])
          elsif upper.respond_to?(:push_others)
            debug "#{self}.upper = #{upper.class}"
            @stat[:rx] += 1
            upper.push_others(pkt, lower)
          else
            debug "#{self}.upper = #{upper.class}"
            @stat[:drop] += 1
          end
        else
          debug "#{self}.upper = #{upper.class}"
          @stat[:rx] += 1
          @upq_upper.push([pkt, lower])
        end
      end

      public
      def recv
        @upq_upper.pop
      end

      ################
      # flow down
      #    down a packet from the upper layer instance

      public
      def send(dst=nil, pkt)
        @stat[:tx] += 1

        debug "#{self.to_s}.send(#{pkt.inspect})"

        unless pkt.kind_of?(Nwdiy::Packet::Ethernet)
          pkt = Nwdiy::Packet::Ethernet.new(dst: dst,data: pkt)
        end
        if pkt.src == "00:00:00:00:00:00" && @addr != nil
          pkt.src = self.addr
        end

        # do not flow-down the packet to me
        if self.forme?(pkt)
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
        debug "#{self.to_s}.flowdown() #{pkt.inspect}"
        pkt = self.capsule(pkt)
        debug "#{self.to_s}.flowdown() #{pkt.inspect}"
        lower = @instance_lower
        debug "#{self.to_s}.flowdown <- @downq_upper.pop (#{@downq_upper.length} entries) -> #{lower}"
        if lower
          lower.send(pkt)
        end
      end
      def capsule(pkt)
        return pkt
      end

      public
      def pop
        debug "#{self.to_s}.pop <- @downq_upper.pop (#{@downq_upper.length} entries)"
        @downq_upper.pop
      end

      ################
      # packet queue length
      def max
        @upq_upper.max
      end
      def max=(n)
        @upq_upper.max = n
        @upq_lower.max = n
        @downq_upper.max = n
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
        debug "#{self}: #{pkt.class}"
        return nil unless pkt.kind_of?(Nwdiy::Packet::Ethernet)
        debug "#{self}: #{pkt.class}"
        return self[pkt.type]
      end
    end
  end
end
