#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

require "io/wait"

Thread.abort_on_exception = true

class Nwdiy::Func::Out::Ethernet < Nwdiy::Func::Out

  class EthError < Exception; end

  @@name_seed = 0

  public
  def initialize(name = nil)
    # 名無しなら自動で名付け
    unless name
      name = sprintf("diy%03u", @@name_seed)
      @@name_seed += 1
    end
    # パケットをやりとりするための @sock を作る
    debug name
    @sock = self.class.open_pfpacket(name) || self.class.open_sock(name)
    debug @sock
  end

  def ready?
    @sock.ready?
  end

  def recv
    unless self.power
      return nil
    end
    Nwdiy::Packet::Ethernet.new(@sock.nwdiy_recv)
  end

  def send(pkt)
    unless pkt.kind_of?(Nwdiy::Packet::Ethernet)
      raise EthError.new "packet #{pkt.inspect}(#{pkt.class}) is not Nwdiy::Packet::Ethernet" 
    end
    raise Errno::EWOULDBLOCK.new "#{self} is down" unless self.power
    @sock.nwdiy_send(pkt.to_pkt)
  end

  ################
  # PF_PACKET ソケットを扱う
  #private
  def self.open_pfpacket(name)
    ifindex = self.if_nametoindex(name)
    debug "#{name}(#{ifindex})"
    return nil unless ifindex   # 実在しない
    begin
      return self.open_pfpacket_detail(name, ifindex)
    rescue Errno::EPERM => e    # 権限がない場合
      $stderr.puts "open(#{name}) => #{e}"
      return nil
    end
  end
  def self.if_nametoindex(name)
    Socket::getifaddrs.each do |ifp|
      next       unless ifp.name == name
      return nil unless ifp.respond_to?(:ifindex)
      return ifp.ifindex
    end
    return nil
  end
  def self.open_pfpacket_detail(name, ifindex)
    ifp = Socket.new(Socket::AF_PACKET, Socket::SOCK_RAW, Nwdiy::ETH_P_ALL.htons)
    ifp.extend SockPFPKT
    ifp.bind(Socket.pack_sockaddr_ll(Nwdiy::ETH_P_ALL, ifindex))
    ifp.autoclose = true
    ifp.clean
    ifp.set_promisc(ifindex)
    ifp
  end

  module SockPFPKT
    # open 後かつ bind 前に受信したパケットには
    # 別インタフェースで受信したパケットが混ざりこんでいる
    # だから bind 直後に掃除する
    def clean
      buf = ""
      loop do
        begin
          self.read_nonblock(1, buf)
        rescue Errno::EAGAIN, Errno::EWOULDBLOCK
          return # DONE (completely removed)
        rescue Errno::EINTR
          # retry
        end
      end
    end
    # MAC が自分宛でなくても受信できるようにする
    def set_promisc(ifindex)
      self.setsockopt(Nwdiy::SOL_PACKET, Nwdiy::PACKET_ADD_MEMBERSHIP, [ifindex, Nwdiy::PACKET_MR_PROMISC].pack("I!S!x10"))
    end

    # パケット送受信
    def nwdiy_recv
      self.sysread(65536)
    end
    def nwdiy_send(pkt)
      self.syswrite(pkt)
    end
  end

  ################
  # TCP ソケットを扱う
  #private
  def self.open_sock(name)
    debug "#{name}"
    begin
      ifp = TCPSocket.new("::1", $NWDIY_INTERFACE_PROXY_PORT)
      debug ifp
    rescue Errno::ECONNREFUSED
      self.start_server
      retry
    end
    ifp.autoclose = true
    ifp.extend SockTCP
    ifp.register(name) # プロキシに登録する
    ifp
  end

  module SockTCP
    def register(name)
      Nwdiy::Func::Out::Ethernet.debug self.nwdiy_send(name)
      Nwdiy::Func::Out::Ethernet.debug self.nwdiy_recv
    end

    # パケット送受信
    def nwdiy_recv
      size = self.sysread(2).unpack("n")[0]
      pkt = self.sysread(size)
      Nwdiy::Func::Out::Ethernet.debug "#{[self]}.recv = #{pkt.dump}"
      pkt
    end
    def nwdiy_send(pkt)
      Nwdiy::Func::Out::Ethernet.debug "[#{self}].send(#{pkt.dump})"
      self.syswrite([pkt.bytesize].pack("n") + pkt) - 2
    end
  end

  ################
  # TCP ソケットをとりまとめるサーバ
  #private
  @@tcpserver = nil
  def self.start_server
    debug "starting..."

    # 待ち受けソケット
    @@sock = TCPServer.new("::1", $NWDIY_INTERFACE_PROXY_PORT)

    # インタフェース名ごとの Nwdiy::Func::Out::Ethernet インスタンス配列
    @@peer = Hash.new { |hash,key| hash[key] = Array.new }

    # ファイルデスクリプタごとの、インタフェース名
    @@name = Hash.new

    # インタフェース名ごとの、PF_PACKET インタフェース
    @@pfpkt = Hash.new

    @@tcpserver = Thread.new do
      loop do

        @@peer.each do |name, list|
          list.delete_if do |io|
            if io.closed?
              @@name.delete(io)
              true
            else
              false
            end
          end
        end
        @@peer.delete_if do |name, list|
          if list.length == 0
            pfpkt = @@pfpkt.delete(name)
            pfpkt.close if pfpkt
            true
          else
            false
          end
        end

        check = [@@sock]
        check += @@peer.values.flatten
        check += @@pfpkt.values.compact

        debug "@@sock=#{@@sock} @@peer=#{@@peer} @@pfpkt=#{@@pfpkt}"

        can_read, _ = IO.select(check)
        can_read.each do |io|
          if io == @@sock
            accept_newsock(io)
          else
            forward_data(io)
          end
        end

      end
    end

  end

  # 新しいアクセスが来たので、インタフェース名を教えてもらって登録する
  def self.accept_newsock(sock)
    # ソケット作成
    debug "accepting..."
    acc = sock.accept
    acc.autoclose = true
    acc.extend SockTCP
    debug "accept #{acc}"

    # インタフェース名を教えてもらう
    begin
      name = acc.nwdiy_recv
      debug name
    rescue EOFError
      return
    end

    # 登録
    @@peer[name] << acc
    @@name[acc] = name

    debug @@pfpkt

    # 可能であれば、PF_PACKET のソケットも用意する
    unless @@pfpkt.has_key?(name)
      pfpkt = self.open_pfpacket(name)
      if pfpkt
        @@pfpkt[name] = pfpkt
        @@name[pfpkt] = name
      end
    end

    # 最後に Ack を返す
    debug name
    acc.nwdiy_send(name)

  end

  # パケットが来たので転送する
  def self.forward_data(io)
    name = @@name[io]
    # まずそこに来てるパケットを受信する
    # あるいはクローズ処理する
    begin
      pkt = io.nwdiy_recv
    rescue Errno::ECONNRESET, EOFError, IOError
      io.close
      return
    end
    # 他のインタフェースに転送する
    (@@peer[name] + [@@pfpkt[name]]).each do |peer|
      next unless peer
      next if peer == io
      begin
        peer.nwdiy_send(pkt)
      rescue Errno::ECONNRESET, IOError
        peer.close
      end
    end
  end

end
