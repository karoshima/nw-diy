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
#    インターフェース ifp に、random な MAC addrを割り当てる
#    インターフェース ifp に、引数で指定された IP addr を割り当てる
#    (ifp はイーサネットインターフェースであること)
# pinger.ping(アドレス)
#    ifp に ARP req, ICMPv4 Echo を送信し、
#    ifp からの ICMPv4 EchoReply を受信する
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
      @ifp = ifp.kind_of?(NwDiy::Interface) ? ifp : NwDiy::Interface.new(ifp)
      @ifp.local or @ifp.local(NwDiy::Packet::MacAddr.new(:local))
      @localip = localip.kind_of?(IPAddr) ? localip : IPAddr.new(localip, Socket::AF_INET)
    end

    def ping(addr)
      addr.kind_of?(IPAddr) or
        addr = IPAddr.new(addr, Socket::AF_INET)
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
    end

    def arpResolve(addr)
      @mactable and @mactable[addr.to_s] and
        return @mactable[addr.to_s]
      eth = NwDiy::Packet::Ethernet.new
      eth.dst = NwDiy::Packet::MacAddr.new('ff-ff-ff-ff-ff-ff')
      eth.src = @ifp.local
      eth.data = arp = NwDiy::Packet::ARP.new
      arp.oper = :request
      arp.sndmac = @ifp.local
      arp.sndip4 = @localip
      arp.tgtip4 = addr
      @ifp.send(eth)
      loop do
        eth = @ifp.recv
        puts eth.type
        (eth.type == 0x0806) or
          next
        puts eth.dst
        puts @ifp.local
        (eth.dst == @ifp.local) or
          next
        puts eth.data.oper
        eth.data.response? or
          next
        puts eth.data.sndip4
        (eth.data.sndip4 == addr) or
          next
        puts eth
        break
      end
      @mactable or
        @mactable = Hash.new
      return @mactable[addr.to_s] = eth.data.sndmac
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
          unless (eth.data.dst == @localip)
            puts "ignore ip.dst = " + eth.data.dst + " != me"
            next
          end
          unless (eth.data.proto == 1)
            puts "ignore ip.proto = " + eth.data.proto + " != ICMP"
            next
          end
          unless (eth.data.data.type == 8)
            puts "ignore ICMP type = " + eth.data.data.type + " != Echo"
            next
          end
          eth.data.data.type = 0
          eth.data.dst = eth.data.src
          eth.data.src = @localip
          eth.dst = eth.src
          eth.src = @ifp.local
          @ifp.send(eth)
        else
          puts "ignore ether.type = " + eth.type4 + " != IP,ARP"
        end
      end
    end

  end
end
