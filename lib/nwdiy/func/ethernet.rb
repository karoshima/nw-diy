#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# Nwdiy::Func::Ethernet はイーサネットインターフェースです。
# 
# new 時に以下の引数を与えることができます。
#
# - OS (Linux kernel) のインターフェース名 
#
#      OS のインターフェースを使います。
#      あらかじめ root 権限で util/ether-daemon.rb を動かしておけば
#      アプリ本体に root 権限は不要です。
#      util/ether-daemon.rb がない場合、アプリ本体に root 権限が必要です。
#
# - OS のインターフェースではない文字列
#
#      OS 非依存の NW-DIY 専用インターフェースを使います。
#      root 権限は不要です。
################################################################

require "socket"

require "nwdiy/func"
require "nwdiy/packet/ethernet"

class Nwdiy::Func::Ethernet
  include Nwdiy::Func

  def initialize(name)
    raise ArgumentError.new("no interface name") unless name
    begin
      @dev = Pcap.new(name)
    rescue Errno::ENOENT, Errno::EPERM
      @dev = Proxy.new(name)
    end
  end

  def ready?
    @dev.ready?
  end

  def send(pkt)
    @dev.sendpkt(pkt)
  end
  def recv
    @dev.recvpkt
  end

  ################################################################
  # PF_PACKET ソケットを使ってパケットを送受信します
  class Pcap < Socket
    def initialize(name)
      link = Socket.getifaddrs.select do |ifp|
        ifp.name == name && ifp.addr.afamily == Socket::AF_PACKET
      end
      raise Errno::ENOENT unless link[0]
      @index = link[0].ifindex
      sockaddr_ll = [AF_PACKET, Nwdiy::ETH_P_ALL, @index].pack("S!nI!x12")
      super(PF_PACKET, SOCK_RAW, Nwdiy::ETH_P_ALL.htons)
      self.bind(sockaddr_ll)
      self.cleanup_socket
      self.set_promisc
    end

    def sendpkt(pkt)
      send(pkt, 0)
    end
    def recvpkt
      recv(65536)
    end

    protected

    def cleanup_socket
      buf = ''
      loop do
        begin
          self.read_nonblock(1, buf)
        rescue Errno::EAGAIN, Errno::EWOULDBLOCK
          return # DONE
        rescue Errno::EINTR
          # retry
        end
      end
    end

    def set_promisc
      mreq = [@index, Nwdiy::PACKET_MR_PROMISC].pack("I!S!x10")
      self.setsockopt(Nwdiy::SOL_PACKET, Nwdiy::PACKET_ADD_MEMBERSHIP, mreq)
    end
  end

  ################################################################
  # デーモンを起こし、そのデーモンを通してパケットを送受信します

  PROXYPORT = 43218

  module ProxyExchange
    # Proxy 通信ではパケット先頭にパケットサイズを付加する
    def sendpkt(pkt)
      len = pkt.bytesize
      ret = send([len, pkt].pack("Na*"), 0)
      return len
    end
    def recvpkt
      begin
        len = recv(4)
        return "" unless len && len.length == 4
        len = len.unpack("N")[0]
        return "" if len <= 0
        return recv(len)
      rescue Errno::ECONNRESET
        return ""
      end
    end
  end

  class Proxy < TCPSocket
    include ProxyExchange

    def initialize(name)
      begin
        super("::1", PROXYPORT)
      rescue Errno::ECONNREFUSED
        begin
          daemon = ProxyDaemon.new
          Thread.new { daemon.run }
        rescue Errno::EADDRINUSE
          sleep 0.1
        end
        retry
      end

      self.sendpkt(name) # デーモンに name を登録し
      self.recvpkt       # 登録完了を確認します (ack の内容は不要なので破棄)
    end

  end

  ################################################################
  # パケットを送受信するためのデーモンです
  class ProxyDaemon

    include Nwdiy::Debug

    def initialize
      @listen = TCPServer.new("::1", PROXYPORT)
      @listen.autoclose = true
      @listen.setsockopt(:SOCKET, :REUSEADDR, true)
      @name2ifp = Hash.new { |hash,key| hash[key] = Array.new }
      @ifp2name = Hash.new
    end

    def run
      Thread.abort_on_exception = true

      self.debugging
      self.debug("Start ProxyDaemon")

      loop do

        self.debug("@name2ifp = #{@name2ifp}")
        self.debug("@ifp2name = #{@ifp2name}")

        reading = [@listen] + @name2ifp.values.flatten
        self.debug("listening #{reading}")
        recv, = IO.select(reading)
        recv.each do |ifp|
          next unless ifp.ready?

          if ifp == @listen
            self.debug("new connection has come")
            self.newsock
          else
            self.forward(ifp)
          end
        end
      end
    end

    # 新規インターフェースが申告されたら
    # インスタンスに登録したうえで
    # ack を返す
    # なお Proxy で PF_PACKET でインターフェースを開けるなら
    # ここで開いて proxy を通してできるようにさせる
    def newsock
      begin
        so = @listen.accept
      rescue Errno::EAGAIN, Errno::EINTR
        return
      end
      so.extend(ProxyExchange)
      so.autoclose = true
      name = so.recvpkt
      if name.length == 0
        self.debug("new connection is already broken.")
        return
      end
      if @name2ifp[name].length == 0
        begin
          pfpkt = Pcap.new(name)
          @name2ifp[name] << pfpkt
          @ifp2name[pfpkt.fileno] = name
          self.debug("open PF_PACKET #{name}")
        rescue Errno::ENOENT, Errno::EPERM => e
          self.debug("open PF_PACKET #{name} => #{e}")
        end
      end
      @name2ifp[name] << so
      @ifp2name[so.fileno] = name
      begin
        so.sendpkt(name)
        self.debug("register socket(#{so.fileno}) in #{name}")
      rescue Errno::ECONNRESET
        self.delsock(so)
        self.debug("undo for broken socket(#{so.fileno})")
      end
    end

    # パケットを受信して、同一名称インターフェースに配る
    # ソケットの close も検知する
    def forward(ifp)
      name = @ifp2name[ifp.fileno]
      self.debug("new packet has come from #{name}(#{ifp.fileno}): @ifp2name=#{@ifp2name}")
      pkt = ifp.recvpkt
      self.debug("new packet is #{pkt.length} bytes")
      if pkt.length == 0
        # EOF ならインターフェースがクローズされたので削除する
        self.delsock(ifp)
        return
      end

      tobewritten = @name2ifp[name] - [ifp]
      self.debug("sending it to #{tobewritten}")
      return if tobewritten.length == 0

      sel = IO.select([], tobewritten)
      sel[1].each do |dst|
        self.debug("forward packet from socket(#{ifp.fileno}) to (#{dst.fileno}) in #{name}")
        begin
          dst.sendpkt(pkt)
        rescue Errno::ECONNRESET, Errno::EPIPE
          self.delsock(dst)
        end
      end
    end

    # ダメになっちゃったソケットを削除する
    def delsock(ifp)
      name = @ifp2name[ifp.fileno]
      @name2ifp[name].delete(ifp)
      @ifp2name.delete(ifp.fileno)
      self.debug("remove socket(#{ifp.fileno}) in #{name}")
      case @name2ifp[name].length
      when 0
        @name2ifp.delete(name)
        self.debug("remove #{name}")
      when 1
        if @name2ifp[name][0].instance_of?(Pcap)
          # 最終的に残ったのが Pcap だけであれば
          # もうそのパケットを受ける奴もいなくなったので
          # Pcap も取り除く
          pfpkt = @name2ifp[name][0]
          @name2ifp.delete(name)
          @ifp2name.delete(pfpkt.fileno)
          self.debug("remove socket(#{pfpkt.fileno}) in #{name}")
        end
      end
    end
  end
end
