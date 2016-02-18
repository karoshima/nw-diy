#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require_relative '../util'
require_relative 'mac'

class NWDIY
  class PKT
    class Ethernet

      def initialize(pkt = nil)
        if (pkt.kind_of?(String) && pkt.bytesize > 14)
          self.dst = pkt[0..5]
          self.src = pkt[6..11]
          self.type = pkt[12..13]
          self.data = pkt[14..10000000000]
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
        @type ||
          NWDIY::PKT::Ethernet::Type.new(@data ?
                                         @data.bytesize :
                                         0)
      end

      def data=(body)
        @data = body
      end
      def data
        @data
      end

      def length
        14 + @data.bytesize
      end

      def to_s
        '[Ethernet dst=' + @dst.to_s + ', src=' + @src.to_s + ', type=' + self.type.to_s + ', data=' + @data.to_s + ']'
      end

      def to_pkt
        self.dst.to_pkt + self.src.to_pkt + self.type.to_pkt + self.data
      end

      class Type
        include Comparable

        @@proto = { 0x0800 => 'IPv4',
                    0x0806 => 'ARP',
                    0x8137 => 'IPX',
                    0x86dd => 'IPv6',
                    0x8863 => 'PPPoE-Discovery',
                    0x8864 => 'PPPoE-Session',
                    0x8100 => 'VLAN',
                    0x88a8 => '802.1AD' }

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
        def to_pkt
          [@type.htons].pack('S!')
        end
        def to_s
          @@proto[@type] || sprintf('0x%04x', @type)
        end
      end

    end
  end
end
