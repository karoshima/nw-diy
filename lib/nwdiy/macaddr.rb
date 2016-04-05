#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# IPAddr クラスそっくりな MacAddr クラス

class NWDIY
  class MacAddr

    # バイナリデータから MAC データを作って返す
    def self::new_ntoh(addr)
      self.new(addr)
    end

    def self::ntop(addr)
      self.new(addr).to_s
    end

    def initialize(addr)
      if addr.size == 6
        @addr = addr
        return
      end
      match = /^(\h\h?):(\h\h?):(\h\h?):(\h\h?):(\h\h?):(\h\h?)$/.match(addr)
      match or
        match = /^(\h\h?)-(\h\h?)-(\h\h?)-(\h\h?)-(\h\h?)-(\h\h?)$/.match(addr)
      match or
        match = /^(\h\h?)\.(\h\h?)\.(\h\h?)\.(\h\h?)\.(\h\h?)\.(\h\h?)$/.match(addr)
      match or
        raise ArgumentError.new("invalid MAC addr: #{addr}")
      @addr = match[1..6].map{|h|h.hex}.pack('C6')
    end

    def hton
      @addr
    end

    def to_s
      @addr.unpack('C6').map{|h|sprintf('%02x',h)}.join(':')
    end
    alias inspect to_s
    alias to_string to_s

    def unicast?
      (@addr.unpack('C') & 0x02) == 0
    end
    def multicast?
      !self.unicast?
    end
    def global?
      (@addr.unpack('C') & 0x01) == 0
    end
    def local?
      !self.global?
    end
  end
end
