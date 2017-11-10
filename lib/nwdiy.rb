#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require "socket"
require "nwdiy/version"
require "nwdiy/config"

module Nwdiy

  autoload(:Debug,     'nwdiy/debug')
  autoload(:Func,      'nwdiy/func')
  autoload(:Packet,    'nwdiy/packet')

  ################
  # /usr/include on Linux

  #include <bits/socket.h>
  SOL_PACKET = 263

  #include <linux/if_ether.h>
  ETH_P_ALL = 0x0003

  #include <linux/if_packet.h>
  PACKET_ADD_MEMBERSHIP  = 1
  PACKET_DROP_MEMBERSHIP = 2
  PACKET_MR_PROMISC = 1

  ################
  # /etc/<file> などから番号や名前を得る
  # よく分からなかったらそのまま返す
  def self.etc(name)
    Etc.resolv(name)
  end
  class Etc < Hash
    @@etc = nil
    def self.resolv(name)
      @@etc = self.new unless @@etc
      @@etc[name] || name
    end
    def initialize
      for path in ["/etc/ethertypes", "/etc/protocols", "/etc/services",
                   "c:/windows/system32/drivers/etc/protocol",
                   "c:/windows/system32/drivers/etc/services"]
        begin
          open(path) do |file|
            file.each do |line|
              line.gsub!(/#.*/, '')
              words = line.split(/\s+/)
              next unless words.length >= 2
              self[words[0]] = words[1]
              self[words[1]] = words[0]
            end
          end
        rescue Errno::ENOENT
          # ignore the unexisting file
        end
      end
    end
  end
end

################################################################
# バイナリデータと uintX_t 数値との相互変換
class String
  def btoh
    self.bytes.inject(0) {|result,item| (result << 8) | item }
  end
end
class Integer
  def htob32
    [self].pack('N')
  end
  def htob16
    [self].pack('n')
  end
  def htob8
    [self].pack('C')
  end
end
# Integer にバイトオーダー変換の機能を追加
class Integer
  def htonl
    self.htob32.unpack("L")[0]
  end
  def htons
    self.htob16.unpack("S")[0]
  end
end

################################################################
# sockaddr_ll 拡張
# (これって Linux 固有っぽい)

################
# Socket に sockaddr_ll 関連のクラスメソッドを拡張する
class Socket
  def self.pack_sockaddr_ll(protocol, ifindex, hatype=0, pkttype=0, addr="")
    [AF_PACKET, protocol, ifindex, hatype, pkttype, addr.length, addr].
      pack("S!nI!S!CCa8")
  end

  def self.unpack_sockaddr_ll(sockaddr)
    sll = sockaddr.unpack("S!nI!S!CCa*")
    sll[6] = sll[6][0..sll[5]]
    sll
  end
end
class << Socket
  alias :sockaddr_ll :pack_sockaddr_ll
end

################
# Addrinfo に sockaddr_ll 関連のインスタンスメソッドを拡張する
class Addrinfo
  def packet?
    self.afamily == Socket::AF_PACKET
  end
  def ifindex
    sll unless @ifindex
    @ifindex
  end
  def hatype
    sll unless @hatype
    @hatype
  end
  def addr
    sll unless @addr
    @addr
  end
  def sll
    raise SocketError("need AF_PACKET address") unless self.packet?
    _, _, @ifindex, @hatype, @pkttype, _, @addr =
      Socket.unpack_sockaddr_ll(self.to_sockaddr)
  end
  protected :sll
end
