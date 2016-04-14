#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require_relative '../nwdiy';

require 'socket'

require 'nwdiy/iplink'

################################################################
# バイナリデータと uintX_t 数値との相互変換
class String
  def btoh
    self.bytes.inject(0) {|result,item| (result << 8) | item }
  end
end
class Integer
  def btoh
    self
  end
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
class NilClass
  def btoh
    nil
  end
  def htob32
    "\0\0\0\0"
  end
  def htob16
    "\0\0"
  end
  def htob8
    "\0"
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
# Linux 関連
class NWDIY
  module Linux

    # /usr/include/linux/if_ether.h
    ETH_P_ALL = 0x0003

    # /usr/include/bits/socket.h
    PF_PACKET = 17
    AF_PACKET = 17
    SOCK_RAW  = Socket::SOCK_RAW
    SOL_PACKET = 263

    # /usr/include/linux/if_packet.h
    PACKET_ADD_MEMBERSHIP = 1
    PACKET_DROP_MEMBERSHIP = 2
    PACKET_MR_PROMISC = 1

    # アプリと root 権限デーモンとのやりとりソケット
    DAEMON_SOCKFILE = '/tmp/.nwdiy_daemon'

    ################
    # 数値あるいは文字列から ifindex と ifname を求める
    def ifindexname(arg)
      ifp = NWDIY::IPLINK.new[arg]
      ifp or
        raise ArgumentError.new("Unknown device: #{arg}");
      [ifp.index, ifp.name]
    end

    ################
    # sockaddr_ll の操作
    def pack_sockaddr_ll(protocol = ETH_P_ALL, index)
      [AF_PACKET, protocol, index].pack("S!nI!x12")
    end

    ################
    # /etc/services などから番号を得る
    def resolv(path, name)
      begin
        open(path) do |file|
          case name
          when Integer then n2 = name.to_s
          when String  then n2 = name.downcase
          else              n2 = name
          end
          file.each do |line|
            line.gsub!(/#.*/, '')
            words = line.split(/\s+/)
            words.length > 0 or next
            words.each do |w|
              w.downcase == n2 and
                return words
            end
          end
        end
      rescue
      end
      name
    end
  end

end

################################################################
# recvfrom や Socket::getifaddrs の結果として
# 生成される Addrinfo (sockaddr_ll) を読みたいので、
# Addrinfo を sockaddr_ll 向けに拡張する
class Addrinfo

  def ether?
    self.afamily == Socket::AF_PACKET
  end

  alias ipproto protocol
  def protocol
    self.ether? and
      return self.ethertype
    self.ipproto
  end

  def ifindex
    self.unpack[2]
  end
  def hatype
    self.unpack[3]
  end
  def pkttype
    self.unpack[4]
  end
  def halen
    self.unpack[5]
  end
  def mac
    self.unpack[6]
  end

  def unpack
    @mac and return @mac
    @mac = self.to_sockaddr.unpack("S!nI!S!CCa*")
  end
end
