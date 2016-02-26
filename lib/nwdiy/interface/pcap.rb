#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# ruby で綴る、AF_PACKET による VM interface

require_relative '../../nwdiy'

require 'nwdiy/util'
require 'nwdiy/packet'

class NWDIY
  class IFP
    class Pcap
      include NWDIY::Linux

      def initialize(name)
        @index, @name = ifindexname(name)
        @sock = Socket.new(PF_PACKET, SOCK_RAW, ETH_P_ALL.htons)
        @sock.bind(pack_sockaddr_ll(@index))
        self.clean
        self.set_promisc
      end

      ################
      # open 後 bind 前に受信してしまったパケットを
      # 掃除する
      def clean
        buf = ''
        loop do
          begin
            @sock.read_nonblock(1, buf)
          rescue Errno::EAGAIN, Errno::EWOULDBLOCK
            return # DONE
          rescue Errno::EINTR
            # retry
          end
        end
      end

      ################
      # promisc モード on
      def set_promisc
        opt = PACKET_ADD_MEMBERSHIP
        mreq = [@index, PACKET_MR_PROMISC].pack("I!S!x10")
        @sock.setsockopt(SOL_PACKET, opt, mreq)
      end

      ################
      # socket op
      def recv
        pkt = @sock.recv(65540)
        NWDIY::PKT::Ethernet.new(pkt)
      end
      def send(pkt)
        pkt.respond_to?(:to_pkt) and
          pkt = pkt.to_pkt
        @sock.send(pkt, 0)
      end
      def close
        @sock.close
      end
    end
  end
end
