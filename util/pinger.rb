#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# ruby で綴る、簡易で adhoc な、arp と ping の送信ツール
################################################################
# pinger = NwDiy::Pinger.new(ifp, localip)
#    ifp はイーサネットインターフェースであること
# pinger.ping(アドレス)
#    ifp に ARP req, ICMPv4 Echo を送信し、ifp からの ICMPv4 EchoReply を受信する
# pinger.pong
#    ifp で ARP, ICMPv4 に応答する

require_relative '../lib/nwdiy'

require 'nwdiy/interface'
require 'nwdiy/packet/ethernet'
require 'nwdiy/packet/arp'
require 'nwdiy/packet/ip/icmp/echo'

module NwDiy
  class Pinger

    def initialize(ifp, localip)
      @ifp = ifp
      ifp.local or ifp.local(NwDiy::Packet::MacAddr.new(:local))
      @localip = localip
    end

    def ping(addr)
      case addr
      when IPAddr
        eth = NwDiy::Packet::Ethernet.new
        eth.dst = self.arpResolve(addr)
        puts eth.dst
        eth.src = @ifp.local
        eth.data = ip = NwDiy::Packet::IPv4.new
        ip.src = @localip
        ip.dst = addr
        ip.data = icmp = NwDiy::Packet::IP::ICMP4.new
        icmp.data = NwDiy::Packet::IP::ICMP::EchoRequest.new
        puts eth
        @ifp.send(eth)
        @ifp.recv
      else
        raise addr
      end
    end

    def arpResolve(addr)
      eth = NwDiy::Packet::Ethernet.new
      eth.dst = NwDiy::Packet::MacAddr.new('ff-ff-ff-ff-ff-ff')
      eth.src = @ifp.local
      eth.data = arp = NwDiy::Packet::ARP.new
      arp.oper = :request
      arp.sndmac = @ifp.local
      arp.sndip4 = @localip
      arp.tgtip4 = addr
      @ifp.send(eth)
      eth = @ifp.recv
      eth.data.sndmac
    end

    def pong
      loop do
        eth = @ifp.recv
        case eth.type
        when 0x0806
          (eth.data.tgtip4 == @localip) or
            next
          eth.dst = eth.src
          eth.src = @ifp.local
          eth.data.oper = :response
          eth.data.tgtmac = eth.data.sndmac
          eth.data.tgtip4 = eth.data.sndip4
          eth.data.sndmac = @ifp.local
          eth.data.sndip4 = @localip
          @ifp.send(eth)
        when 0x0800
          (eth.data.proto == 1) or
            next
          (eth.data.data.type == 8) or
            next
          eth.data.data.type = 0
          eth.data.dst = eth.data.src
          eth.data.src = @localip
          eth.dst = eth.src
          eth.src = @ifp.local
          @ifp.send(eth)
          puts eth
        end
      end
    end

  end
end
