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
# irb> ipv4.etherip(peer: "192.0.2.2")
#
#    (1) IPv4 instance creates EtherIP instance,
#        which handles IP proto 97 and peer nodes.
#    (2) @eip creates peer node 192.0.2.2.
#    (3) the new peer node creates Ethernet instance on it.
#    
################################################################

require 'thread'
require 'nwdiy/func/ethernet'

module Nwdiy
  module Func

    ################################################################
    # create an EtherIP instance

    class EtherIP

      IP_PROTO_ETHERIP = 97

      include Nwdiy::Func
      include Nwdiy::Debug

      def initialize(klass)
        name = 'EtherIP'
        debug(name)
        super(name)

        self.peer_init(klass)
        self.pktflow_init
        self.thread_init

      end
    end

    module EtherIPReceiver
      def etherip
        eip = self[EtherIP::IP_PROTO_ETHERIP]
        unless eip
          case self
          when Nwdiy::Func::IPv4
            klass = Nwdiy::Packet::IPv4Addr
          else
            raise "Unknown Function class #{self.class}"
          end
          eip = self[EtherIP::IP_PROTO_ETHERIP] = EtherIP.new(klass)
          eip.lower = self
        end
        return eip
      end
    end

    class IPv4
      include EtherIPReceiver
    end

    class EtherIP
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

      ################################################################
      # Peer configuration

      def peer_init(klass)
        @peerClass = klass
        @node = Hash.new { |hash,key| hash[key] = EtherIPNode.new(self, key) }
      end

      def forme?(pkt, lower_header)
        debug "pkt.kind_of?(Nwdiy::Packet::EtherIP) = #{pkt.kind_of?(Nwdiy::Packet::EtherIP)}"
        debug "(lower_header != nil) = #{lower_header != nil}"
        debug "@node.has_key?(lower_header.src) = #{@node.has_key?(lower_header.src)}"
        debug #{@node}"
        debug "pkt.data.kind_of?(Nwdiy::Packet::Ethernet) = #{pkt.data.kind_of?(Nwdiy::Packet::Ethernet)}" if pkt
        return pkt.kind_of?(Nwdiy::Packet::EtherIP) &&
               lower_header != nil &&
               @node.has_key?(lower_header.src) &&
               pkt.data.kind_of?(Nwdiy::Packet::Ethernet)
      end

      ################################################################
      # upper layers
      public
      def [](peer)
        peer = self.peer(peer)
        return @node[peer]
      end
      def has_key?(peer)
        peer = self.peer(peer)
        debug "#{peer.inspect}(#{peer.class}): #{peer.hash}"
        debug "#{@node.keys[0].inspect}(#{@node.keys[0].class}): #{@node.keys[0].hash}"
        debug "#{peer.hash} #{(peer.hash==@node.keys[0].hash)?('=='):('!=')} #{@node.keys[0].hash}"
        return @node.has_key?(peer)
      end
      protected
      def peer(peer)
        debug "#{peer}(#{peer.class} == #{@peerClass})"
        return peer if peer.kind_of?(@peerClass)
        return @peerClass.new(peer)
      end
    end

    ################################################################
    # create an EtherIP peer node instance

    class EtherIPNode < Ethernet

      def initialize(etherip, peer)
        name = "EtherIP(#{peer.inspect})"
        debug(name)
        super(name, peer)
        self.lower = etherip
      end
    end

    ################################################################
    # internal threads
    class EtherIP
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

    ################################################################
    # packet flow
    class EtherIP
      protected
      def pktflow_init
        @stat = Hash.new { |hash,key| hash[key] = 0 }
        @downq_upper = Nwdiy::Func::PktQueue.new
        @upq_upper = Nwdiy::Func::PktQueue.new
        @upq_lower = Nwdiy::Func::PktQueue.new
      end
    end

    ################
    # flow up
    class EtherIP
      public
      def push(pkt, lower_headers=[])
        unless pkt.kind_of?(Nwdiy::Packet::EtherIP)
          raise Errno::EINVAL
        end
        @upq_lower.push([pkt, lower_headers])
      end

      protected
      def flowup
        pkt, lower_headers = @upq_lower.pop
        debug pkt.inspect, lower_headers
        if self.forme?(pkt, lower_headers.last)
          debug "it is forme"
          @stat[:rx] += 1
          self[lower_headers.last.src].push(pkt.data, lower_headers + [pkt])
        else
          debug "it is not forme"
          @stat[:drop] += 1
        end
      end
    end

    class EtherIPNode
      def push(pkt, lower_headers)
        @upq_upper.push([pkt, lower_headers])
      end

      public
      def recvpkt
        @upq_upper.pop
      end
    end

    ################
    # flow down

    class EtherIPNode
      # sendpkt() is defined in Ethernet
    end

    class EtherIP
      public
      def sendpkt(dst = nil, pkt)
        @stat[:tx] += 1

        debug "#{self.to_s}.sendpkt(#{pkt.inspect})"

        case pkt
        when Nwdiy::Packet::Ethernet
          pkt = Nwdiy::Packet::EtherIP.new(data: pkt)
          pkt = Nwdiy::Packet::IPv4.new(dst: dst,
                                        proto: Nwdiy::Packet::IPv4::IPPROTO_ETHERIP,
                                        data: pkt)
        when Nwdiy::Packet::EtherIP
          pkt = Nwdiy::Packet::IPv4.new(dst: dst,
                                        proto: Nwdiy::Packet::IPv4::IPPROTO_ETHERIP,
                                        data: pkt)
        when Nwdiy::Packet::IPv4
          if pkt.dst == nil
            pkt.dst = dst
          end
        end

        debug "downq_upper.push(#{pkt.inspect})"
        @downq_upper.push(pkt)
        return pkt.bytesize
      end

      protected
      def flowdown
        pkt = @downq_upper.pop
        lower = @instance_lower
        debug "pkt #{pkt.inspect} to #{lower}"
        unless lower
          return
        end
        lower.sendpkt(pkt)
      end

      public
      def pop
        debug "#{self.to_s}.pop <- @downq_upper.pop ("#{@downq_upper.length} entries)"
        @downq_upper.pop
      end
    end
  end
end
