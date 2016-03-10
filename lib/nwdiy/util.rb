#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require_relative '../nwdiy';

require 'socket'

require 'nwdiy/iplink'

################################################################
# Linux 関連
class NWDIY
  module Linux

    # バイナリデータと uintX_t 数値との相互変換
    class String
      def btoh32
        self.unpack('N')[0]
      end
      def btoh16
        self.unpack('n')[0]
      end
      def btoh8
        self.unpack('C')[0]
      end
    end
    class Integer
      def btoh32
        self
      end
      def btoh16
	self
      end
      def btoh8
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
      def btoh32
        nil
      end
      def btoh16
	nil
      end
      def btoh8
	nil
      end
    end      
    # Integer にバイトオーダー変換の機能を追加
    class Integer
      def htonl
        self.htobl.unpack("L")[0]
      end
      def htons
        self.htobs.unpack("S")[0]
      end
    end

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

    ################
    # /etc/services などから番号を得る
    def resolv(path, name)
      begin
        open(path) do |file|
          n2 = name.downcase
          file.each do |line|
            line.gsub!(/#.*/, '')
            title, id, *alt = line.split(/\s+/)
            id or next
            title.downcase == n2 and
              return id
            alt.each do |t2|
              t2.downcase == n2 and
                return id
            end
          end
        end
      rescue
      end
      name
    end
  end

end
