#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2018 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# with Apache-2 license.  check /LICENSE please.
################################################################
# Ethernet interface

require 'thread'

module Nwdiy
  module Func
    class Ethernet

      MAXQLEN = 16

      attr_accessor :to_s
      @pktq

      private
      def initialize(name)
        @pktq = Hash.new { |hash,key| hash[key] = Queue.new }
      end

      def sendpkt(dir, pkt)
        @pktq[dir].push(pkt)
        if MAXQLEN < @pktq[dir].length
          recvpkt(dir)
        end
      end

      def recvpkt(dir)
        @pktq[dir].pop
      end

      public

      # upper layer can send down a packet
      def senddown(pkt)
        sendpkt(:down, pkt)
      end

      # upper layer can recv up a packet
      def recvup
        recvpkt(:up)
      end

      # lower layer can send up a packet
      def sendup(pkt)
        sendpkt(:up, pkt)
      end

      # lower layer can recv down a packet
      def recvdown
        recvpkt(:down)
      end
    end

  end
end
