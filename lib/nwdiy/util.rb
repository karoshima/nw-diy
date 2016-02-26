#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require_relative '../nwdiy';

require 'socket'

require 'nwdiy/iplink'

################
# Integer にバイトオーダー変換の機能を追加
class Integer
  def htonl
    [self].pack("L!").unpack("N")[0]
  end
  def htons
    [self].pack("S!").unpack("n")[0]
  end
  def ntohl
    [self].pack("N").unpack("L!")[0]
  end
  def ntohs
    [self].pack("n").unpack("S!")[0]
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
    # sockaddr_ll を作る
    def pack_sockaddr_ll(index)
      [AF_PACKET, ETH_P_ALL, index].pack("S!nIx12")
    end
  end
end
