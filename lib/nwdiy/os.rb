#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2018 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# with Apache-2 license.  check /LICENSE please.
################################################################

module Nwdiy
  module OS

    def self.ethernet(name)
      pfpkt = Pfpkt.new(name)
      return pfpkt.ethernet
    end

    class Pfpkt

      include Nwdiy::Func::EthernetReceiver

      def initialize(name)
        @ifindex, @ifp = self.class.init_pfpkt(name)
        @eth = self.ethernet

        Thread.new do
          begin
            loop do
              pkt = Nwdiy::Packet::Ethernet.new(@ifp.sysread(65536))
              @eth.push(pkt, [])
            end
          rescue EOFError
          end
        end
      end

      def ethernet
        return @eth if defined?(@eth) && @eth
        @eth = super
      end

      class << self
        def init_pfpkt(name)
          ifindex = if_nametoindex(name)
          ifp = open_pfpkt(ifindex)
          clean_pfpkt(ifp)
          set_promisc_pfpkt(ifindex, ifp)
          return ifindex, ifp
        end
        def if_nametoindex(name)
          Socket.getifaddrs.each do |ifp|
            next unless ifp.name == name
            next unless ifp.respond_to?(:ifindex)
            return ifp.ifindex
          end
          raise Errno::ENOENT
        end
        def open_pfpkt(ifindex)
          ifp = Socket.new(Socket::AF_PACKET, Socket::SOCK_RAW, ETH_P_ALL.htons)
          ifp.bind([Socket::AF_PACKET, ETH_P_ALL, ifindex].pack("S!nI!x12"))
          ifp.autoclose = true
          return ifp
        end
        def clean_pfpkt(ifp)
          buf = ""
          loop do
            begin
              ifp.read_nonblock(1, buf)
            rescue Errno::EAGAIN, Errno::EWOULDBLOCK
              return # DONE (completely removed)
            rescue Errno::EINTR
              # retry
            end
          end
        end
        def set_promisc_pfpkt(ifindex, ifp)
          opt = [ifindex, PACKET_MR_PROMISC].pack("I!S!x10")
          ifp.setsockopt(SOL_PACKET, PACKET_ADD_MEMBERSHIP, opt)
        end
      end
    end

    #include <bits/socket.h>
    SOL_PACKET = 263

    #include <linux/if_ether.h>
    ETH_P_ALL = 0x0003

    #include <linux/if_packet.h>
    PACKET_ADD_MEMBERSHIP  = 1
    PACKET_DROP_MEMBERSHIP = 2
    PACKET_MR_PROMISC = 1
  end
end
