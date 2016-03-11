#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require_relative '../../nwdiy'

require 'nwdiy/util'

class NWDIY
  class PKT

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
        case pkt
        when String
          pkt.bytesize > 14 or
            raise TooShort.new(pkt)
          self.dst = pkt[0..5]
          self.src = pkt[6..11]
          self.type = pkt[12..13]
          pkt[0..13] = ''
          self.data = pkt
        when nil
          self.dst = nil
          self.src = nil
          self.type = nil
          self.data = nil
        else
          raise InvalidData.new(pkt)
        end
      end

      ################################################################
      # 各フィールドの値
      ################################################################

      def dst=(val)
        @dst = NWDIY::PKT::MacAddr.new(val)
      end
      def dst
        @dst
      end

      def src=(val)
        @src = NWDIY::PKT::MacAddr.new(val)
      end
      def src
        @src
      end

      def type=(val)
        case val
        when String
          if val.bytesize == 2
            @type = val.btoh16
          else
            @type = resolv('/etc/ethertypes', val)
            @type or
              raise InvaliData.new(val)
            @type = @type.to_i(16)
          end
        when Integer, nil
          @type = val
        else
          raise InvaliData.new(val)
        end
      end
      def type
        @type
      end

      def data=(val)
        @data = val
      end
      def data
        @data
      end

      ################################################################
      # 設定されたデータを元に、設定されてないデータを補完する
      def compile(overwrite=false)
        # autoload で不要なモジュールの読み込みを防ぐため
        # @type と @data 型の関係は構造化せず case 処理する
        case @data
        when VLAN then klass = 0x8100
        when ARP  then klass = 0x0806
        when IPv4 then klass = 0x0800
        when IPv6 then klass = 0x86dd
        else           klass = nil
        end
        if klass
          if klass != @type
            if !@type or overwrite
              @type = klass
            else
              raise InvalidData.new(sprintf("type:0x%04x != data:%s", @type, @data.class))
            end
          end
        else
          case @type
          when 0x8100 then @data = VLAN.new(@data).compile
          when 0x0806 then @data = ARP.new(@data).compile
          when 0x0800 then @data = IPv4.new(@data).compile
          when 0x86dd then @data = IPv6.new(@data).compile
          else
            @data = Binary.new(@data)
            (@type && @type > 1500) or
              @type = 14 + @data.bytesize
          end
        end
        self
      end

      ################################################################
      # その他の諸々
      def to_pkt
        self.compile
        self.dst.to_pkt + self.src.to_pkt + self.type.htob16 + self.data.to_pkt
      end
      def bytesize
        14 + @data.bytesize
      end
      def to_s
        "[Ethernet dst=#{@dst} src=#{@src} type=#{type} data=#{@data}]"
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
