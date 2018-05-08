#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2018 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# with Apache-2 license.  check /LICENSE please.
################################################################
# Ethernet interface
#
# You can send/recv a packet with this instance.
#
# pkt = eth.recv()
#    You can get a packet received with this Ethernet instance.
#    If you have an upper layer instance such as eth.ip,
#    you can get IP packet from the ip instance (not the eth instance).
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
    class Ethernet

      include Nwdiy::Func

      def initialize(name)
        super
        # my address
        @addr = Nwdiy::Packet::MacAddr.new(:global)
        # my joined group addresses
        @join = Hash.new
        # upper layers
        @type = Array.new
        @upq = Queue.new
        # lower layer
        @downq = Queue.new
        # statistics
        @stat = Hash.new { |hash,key| hash[key] = 0 }
        # size of @upq, @downq
        @qlen = 16
      end

      def close
        @upq.close
        @downq.close
      end

      def addr=(mac)
        @addr = Nwdiy::Packet::MacAddr.new(mac)
      end
      attr_reader :addr

      def join(group = nil)
        if group != nil
          raise Errno::EINVAL unless group.kind_of?(Nwdiy::Packet::MacAddr)
          raise Errno::EINVAL unless group.multicast?
          raise Errno::EINVAL if     group.broadcast?
          @join[group] = true
        end
        return @join
      end
      def leave(group)
        @join.delete(group)
      end

      attr_accessor :qlen

      def push(pkt, lower=[])
        raise Errno::EINVAL unless pkt.kind_of?(Nwdiy::Packet::Ethernet)
        upper = @type[pkt.type]
        if upper
          if pkt.dst == @addr || @join[pkt.dst]
            @stat[:rx] += 1
            upper.push(pkt.data, list + [pkt])
          elsif upper.respond_to?(:push_others)
            @stat[:rx] += 1
            upper.push_others(pkt.data, list + [pkt])
          else
            @stat[:drop] += 1
          end
        else
          @stat[:rx] += 1
          @upq.push([pkt, lower])
        end
      end

      def recv()
        @upq.pop()[0]
      end

      def send(dst=nil, pkt)
        @stat[:tx] += 1

        unless pkt.kind_of?(Nwdiy::Packet::Ethernet)
          eth = Nwdiy::Packet::Ethernet.new(pkt)
          eth.dst = Nwdiy::Packet::MacAddr.new(dst)
          eth.src = @addr
          eth.data = pkt
          pkt = eth
        end

        if pkt.dst == @addr
          @stat[:rx] += 1
          if @type[pkt.type]
            @type[pkt.type].push(pkt)
          else
            @upq.push([pkt.data, []])
          end
          return pkt.bytesize
        end
        if @join[pkt.dst]
          if @type[pkt.type]
            @type[pkt.type].push(pkt.data)
          else
            @upq.push([pkt.data, []])
          end
        end

        pushdown(pkt)
        return pkt.bytesize
      end

      protected
      def pushdown(pkt)
        @downq.push(pkt)
      end
      def popdown
        @downq.pop
      end

      public
      def pop
        popdown
      end

    end
  end
end
