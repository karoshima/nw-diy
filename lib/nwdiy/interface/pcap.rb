#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# ruby で綴る、AF_PACKET による VM interface

require_relative '../../nwdiy'

require 'nwdiy/util'
require 'nwdiy/iplink'
require 'nwdiy/packet'

class NWDIY
  class IFP
    class Pcap
      include NWDIY::Linux

      # /usr/include/linux/if_arp.h
      ARPHRD_LOOPBACK = 772

      # /usr/incluce/netpacket/packet.h
      PACKET_OUTGOING = 4

      def self.packet
        NWDIY::PKT::Ethernet
      end

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
        self.class.packet.new(self.recv_raw)
      end
      def recv_raw
        loop do
          pkt, ll = @sock.recvfrom(65540)
          (ll.hatype == ARPHRD_LOOPBACK && ll.pkttype == PACKET_OUTGOING) and
            redo
          return pkt
        end
      end
      def send(pkt)
        pkt.src.to_s == '00:00:00:00:00:00' and
          pkt.src = self.mac
        pkt.respond_to?(:to_pkt) and
          pkt = pkt.to_pkt
        @sock.send(pkt, 0)
      end
      def close
        @sock.close
      end

      ################
      # 自分の MAC アドレスを調べる
      def mac
        unless @mac
          @mac = NWDIY::IPLINK.new[@index].mac
        end
        @mac
      end
    end
  end
end
