#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require_relative '../../nwdiy'

require 'nwdiy/util'
require 'nwdiy/packet/mac'

class NWDIY
  class PKT

    autoload(:IPv4, 'nwdiy/packet/ipv4')
    autoload(:ARP,  'nwdiy/packet/ipv4')
    autoload(:IPv6, 'nwdiy/packet/ipv6')
    autoload(:VLAN, 'nwdiy/packet/vlan')

    class Ethernet

      def initialize(pkt = nil)
        if (pkt.kind_of?(String) && pkt.bytesize > 14)
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

      def dst=(mac)
        @dst = NWDIY::PKT::MAC.new(mac)
      end
      def dst
        @dst
      end

      def src=(mac)
        @src = NWDIY::PKT::MAC.new(mac)
      end
      def src
        @src
      end

      def type=(ethertype)
        @type = NWDIY::PKT::Ethernet::Type.new(ethertype)
      end
      def type
        @type and return @type
        # ↑ Ethernet
        # ↓ 802.3
        NWDIY::PKT::Ethernet::Type.new(@data ?
                                       @data.length :
                                       0).to_i
      end

      def data=(body)
        @data = NWDIY::PKT::Binary.new(body)
      end
      def data
        @data
      end

      def length
        14 + @data.length
      end

      def to_s
        '[Ethernet dst=' + @dst.to_s + ', src=' + @src.to_s + ', type=' + self.type.to_s + ', data=' + @data.to_s + ']'
      end

      def to_pkt
        self.dst.to_pkt + self.src.to_pkt + self.type.to_pkt + self.data.to_pkt
      end

      class Type
        @@proto = { 0x0800 => 'IPv4',
                    0x0806 => 'ARP',
                    0x86dd => 'IPv6',
                    0x8100 => 'VLAN' }

        def initialize(type=0)
          case type
          when Integer
            @type = type
          when String
            @type = type.to_i
            @type > 0 and return
            @type = @@proto.key(type)
            @type and return
            @type = type.unpack('S!')[0]
          when nil
            @type = 0
          else
            raise ArgumentError.new("invalid Ethertype: #{type}")
          end
        end
        def <=>(other)
          @type - other
        end
        def to_i
          @type
        end
        def to_pkt
          [@type.htons].pack('S!')
        end
        def to_s
          @@proto[@type] || sprintf('0x%04x', @type.ntohs)
        end
      end

    end
  end
end
