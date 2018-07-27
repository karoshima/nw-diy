#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2018 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# with Apache-2 license.  check /LICENSE please.
################################################################
# Nwdiy::Func::EtherIP
#    Ethernet over IP interface class
# Nwdiy::Func::EtherIPReceiver
#    instance methods for instances under Nwdiy::Func::EtherIP
#    typically, IPv4 and IPv6
################################################################

require 'thread'
require 'nwdiy/func/ethernet'

module Nwdiy
  module Func

    ################################################################
    # create an EtherIP instance

    class EtherIP
      include Nwdiy::Func
      include Nwdiy::Debug
      include EthernetReceiver

      def initialize(name)
        debug name
        super(name)

        self.pktflow_init
        self.thread_init
      end

    end

    # create an EtherIP instance from the lower layer
    # same as EthernetReceiver

    module EtherIPReceiver
      def etherip(name = self.to_s + ":eip")
        return @eip if @eip
        @eip = EtherIP.new(name)
        @eip.lower = self
        return @eip
      end
    end

    class IPv4
      include EtherIPReceiver
    end

    class EtherIP
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

    # close the instance

    class EtherIP
      public
      def close
        self.thread_stopall
      end
    end

    class EtherIP

      ################################################################
      # internal threads
      protected
      def thread_init
        # thread that flow he packet up & down
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

      def thread_stopall
        @thread_flowdown.kill if @thread_flowdown
        @thread_flowup.kill   if @thread_flowup
        @thread_flowdown.join if @thread_flowdown
        @thread_flowup.join   if @thread_flowup
        @thread_flowdown = nil
        @thread_flowup = nil
      end

      ################################################################
      # packet flow
      protected
      def pktflow_init
        @instance_upper = nil
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
        raise Errno::EINVAL unless pkt.kind_of?(Nwdiy::Packet::EtherIP)
        debug pkt.inspect
        @upq_lower.push([pkt, lower])
      end

      # flow up the incoming packets
      protected
      def flowup
        pkt, lower = @upq_lower.pop
        debug pkt.inspect, lower
        # check the upper layer to pass
        upper_instance = @instance_upper
        if upper_instance
          debug "it is for me."
          @stat[:rx] += 1
          upper_instance.push(pkt.data, lower)
        else
          debug "#{self}.upper = nil"
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
      #    down a packet from the upper laoery instance

      public
      def sendpkt(dst=nil, pkt)
        @stat[:tx] += 1
        debug "#{self.to_s}.sendpkt(#{pkt.inspect})"

        unless pkt.kind_of?(Nwdiy::Packet::EtherIP)
          pkt = Nwdiy::Packet::EtherIP.new(data: pkt)
        end
        
        @downq_upper.push(pkt)
        return pkt.bytesize

      end

      protected
      def flowdown
        debug "#{self.to_s}.flowdown: popping a packet"
        pkt = @downq_upper.pop
        debug "#{self.to_s}.flowdown() #{pkt.inspect}"
        lower = @instance_lower
        if lower
          lower.sendpkt(pkt)
        end
      end

      public
      def pop
        @downq_upper.pop
      end

      ################################################################
      # upper layers
      def eth=(func)
        @instance_upper = func
      end
      def eth
        @instance_upper
      end
    end
  end
end
