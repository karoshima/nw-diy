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

    attr_reader :ifp, :localip

    def ping(addr)
      addr.kind_of?(IPAddr) or
        addr = IPAddr.new(addr, Socket::AF_INET)
      req = NwDiy::Packet::Ethernet.new
      req.dst = self.arpResolve(addr)
      req.src = @ifp.local
      req.data = ip = NwDiy::Packet::IPv4.new
      ip.src = @localip
      ip.dst = addr
      ip.data = icmp = NwDiy::Packet::IP::ICMP4.new
      icmp.data = NwDiy::Packet::IP::ICMP::EchoRequest.new
      puts req
      @ifp.send(req)
      loop do
        res = @ifp.recv
        self.forme?(res, req.dst, addr) or
          next
        res.data.is_a?(NwDiy::Packet::IPv4) or
          next
        res.data.data.is_a?(NwDiy::Packet::IP::ICMP4) or
          next
        res.data.data.data.is_a?(NwDiy::Packet::IP::ICMP::EchoReply) or
          next
        unless res.data.cksum_ok?
          puts "BAD CHECKSUM"
          next
        end
        return res
      end
    end

    def arpResolve(addr)
      @mactable and @mactable[addr.to_s] and
        return @mactable[addr.to_s]
      req = NwDiy::Packet::Ethernet.new
      req.dst = NwDiy::Packet::MacAddr.new('ff-ff-ff-ff-ff-ff')
      req.src = @ifp.local
      req.data = arp = NwDiy::Packet::ARP.new
      arp.oper = :request
      arp.sndmac = @ifp.local
      arp.sndip4 = @localip
      arp.tgtip4 = addr
      @ifp.send(req)
      loop do
        res = @ifp.recv
        (res.type == 0x0806) or
          next
        res.data.response? or
          next
        self.forme?(res, nil, addr) or
          next
        @mactable or
          @mactable = Hash.new
        return @mactable[addr.to_s] = res.data.sndmac
      end
    end

    def pong
      loop do
        eth = @ifp.recv
        self.forme?(eth) or
          next

        case eth.type
        when 0x0806
          unless eth.data.request?
            puts "ignore arp.oper = #{eth.data.oper} != EchoRequest"
            next
          end
          eth.dst = eth.data.sndmac
          eth.src = @ifp.local
          eth.data.oper = :response
          eth.data.tgtmac = eth.data.sndmac
          eth.data.tgtip4 = eth.data.sndip4
          eth.data.sndmac = @ifp.local
          eth.data.sndip4 = @localip
          NwDiy::Interface.debug[:packet] and
            puts "DEBUG: #{@ifp}.send(#{eth})"
          @ifp.send(eth)
        when 0x0800
          unless (eth.data.proto == 1)
            puts "ignore ip.proto = #{eth.data.proto} != ICMP"
            next
          end
          unless (eth.data.data.type == 8)
            puts "ignore ICMP type = #{eth.data.data.type} != Echo"
            next
          end
          unless eth.data.cksum_ok?
            puts "BAD CHECKSUM"
            next
          end
          puts eth
          eth.data.data.type = 0
          eth.data.dst = eth.data.src
          eth.data.src = @localip
          eth.dst = eth.src
          eth.src = @ifp.local
          puts eth
          NwDiy::Interface.debug[:packet] and
            puts "DEBUG: #{@ifp}.send(#{eth})"
          @ifp.send(eth)
        else
          puts "ignore ether.type = #{eth.type4} != IP,ARP"
        end
      end
    end

    def forme?(eth, srcmac = nil, srcip = nil)
      unless eth.is_a?(NwDiy::Packet::Ethernet)
        puts "ignore unknown packet #{eth}"
        return false
      end
      unless eth.dst.multicast? || eth.dst == @ifp.local
        puts "ignore ether.dst = #{eth.dst} != me"
        return false
      end
      if srcmac && eth.src != srcmac
        puts "ignore ethernet.src = #{eth.src} != #{srcmac}"
      end
      case eth.type
      when 0x0806
        if @localip != eth.data.tgtip4
          puts "ignore arp.target = #{eth.data.tgtip4} != me(#{@localip})"
          return false
        end
        if srcip && srcip != eth.data.sndip4
          puts "ignore arp.sender = #{eth.data.sndip4} != #{srcip}"
          return false
        end
      when 0x0800
        if @localip != eth.data.dst
          puts "ignore ip.dst = #{eth.data.dst} != me(#{@localip})"
          return false
        end
        if srcip && srcip != eth.data.src
          puts "ignore ip.src = #{eth.data.dst} != #{srcip}"
          return false
        end
      else
        puts "ignore ether.type = #{eth.type4} != IP,ARP"
        return false
      end
      true
    end

  end
end
