#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require_relative '../../nwdiy'

require 'nwdiy/util'

class NWDIY
  class PKT

    autoload(:UINT16,  'nwdiy/packet/uint16')
    autoload(:IPv4,    'nwdiy/packet/ipv4')
    autoload(:ARP,     'nwdiy/packet/ipv4')
    autoload(:IPv6,    'nwdiy/packet/ipv6')
    autoload(:VLAN,    'nwdiy/packet/vlan')

    class Ethernet
      include NWDIY::Linux

      ################################################################
      # パケット生成
      ################################################################
      # 受信データあるいはハッシュデータからパケットを作る
      def initialize(pkt = nil)
        if pkt.kind_of?(String)
          pkt.bytesize >= 14 or
            raise NWDIY::PKT::TooShort.new("packet TOO short for Ethernet: #{pkt.dump}")
          self.dst = pkt[0..5]
          self.src = pkt[6..11]
          self.type = pkt[12..13]
          pkt[0..13] = ''
          self.data = pkt
        elsif pkt.kind_of?(Hash)
          self.dst = pkt[:dst]
          self.src  = pkt[:src]
          pkt[:type] and self.type = pkt[:type]
          pkt[:data] and self.data = pkt[:data]
        else
          self.dst = nil
          self.src = nil
        end
      end

      ################################################################
      # 各フィールドの値の操作
      ################################################################
      # 宛先 MAC
      def dst=(mac)
        @dst = NWDIY::PKT::MacAddr.new(mac)
      end
      def dst
        @dst
      end

      ################
      # 送信先 MAC
      def src=(mac)
        @src = NWDIY::PKT::MacAddr.new(mac)
      end
      def src
        @src
      end

      ################
      # Ethernet の type あるいは IEEE802.3 の length
      def type=(val)
        val = resolv('/etc/ethertypes', val, :hex)
        val = NWDIY::PKT::UINT16.new(val)
        if val > 1500
          @type = val
        else
          @type = nil
        end
        # data 部は、型が変わるならフォーマット適用やり直し
        (@data && @data.class != self.dataKlass) and
          self.data = @data.to_pkt
      end
      def type
        # Ethernet       802.3
        # ↓              ↓
        @type || (@data ? @data.length : 0)
      end

      ################
      # データ部
      def dataKlass
        # (autoload が効くように、配列やハッシュにせずコードで列挙する)
        case @type
        #when 0x0806 then NWDIY::PKT::ARP
        when 0x0800 then NWDIY::PKT::IPv4
        #when 0x86dd then NWDIY::PKT::IPv6
        #when 0x8100 then NWDIY::PKT::VLAN
        else             NWDIY::PKT::Binary
        end
      end
      def data=(body)
        @data = nil
        case body
        when nil then return
        #when NWDIY::PKT::ARP  then @type = 0x0806
        when NWDIY::PKT::IPv4 then @type = 0x0800
        #when NWDIY::PKT::IPv6 then @type = 0x86dd
        #when NWDIY::PKT::VLAN then @type = 0x8100
        else body = self.dataKlass.new(body)
        end
        @data = body
      end
      def data
        @data
      end

      ################################################################
      # その他の諸々
      def length
        14 + @data.length
      end
      def to_s
        '[Ethernet dst=' + @dst.to_s + ' src=' + @src.to_s + ' type=' + self.type.to_s + ' data=' + @data.to_s + ']'
      end
      def to_pkt
        self.dst.to_pkt + self.src.to_pkt + self.type.to_pkt + self.data.to_pkt
      end

    end

    class MacAddr

      # バイナリ (6byte), String, NWDIY::PKT::MAC を元に MAC アドレスを生成する
      def initialize(mac = nil)
        case mac
        when String
          if (mac.bytesize == 6)
            @addr = mac
          else
            match = /^(\h\h?):(\h\h?):(\h\h?):(\h\h?):(\h\h?):(\h\h?)$/.match(mac)
            match or
              match = /^(\h\h?)-(\h\h?)-(\h\h?)-(\h\h?)-(\h\h?)-(\h\h?)$/.match(mac)
            match or
              match = /^(\h\h?)\.(\h\h?)\.(\h\h?)\.(\h\h?)\.(\h\h?)\.(\h\h?)$/.match(mac)
            match or
              raise ArgumentError.new("invalid MAC addr: #{mac}")
            mac = match[1..6].map {|m| m.hex}
            @addr = mac.pack('C6')
          end
        when NWDIY::PKT::MacAddr
          @addr = mac.to_pkt
        when nil
          @addr = [0,0,0,0,0,0].pack('C6')
        else
          raise ArgumentError.new("invalid MAC addr: #{mac}");
        end
      end

      # パケットに埋め込むデータ
      def to_pkt
        @addr
      end

      # MAC の文字列表現
      def to_s
        @addr.unpack('C6').map{|h|sprintf('%02x',h)}.join(':')
      end

    end
  end
end
