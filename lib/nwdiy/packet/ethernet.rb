#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require_relative '../../nwdiy'

require 'nwdiy/util'
require 'nwdiy/packet/uint16'
require 'nwdiy/packet/mac'

class NWDIY
  class PKT

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
        tmp = NWDIY::PKT::Ethernet::Type.new(ethertype)
        (tmp > 1500) and
          @type = tmp
      end
      def type
        @type and return @type
        # ↑ Ethernet
        # ↓ 802.3
        NWDIY::PKT::Ethernet::Type.new(@data ?
                                       @data.length :
                                       0).to_i
      end
      class Type < NWDIY::PKT::UINT16
        TYPES = {
          'IPv4' => 0x0800,
          'ARP'  => 0x0806,
          'IPv6' => 0x86dd,
          'VLAN' => 0x8100 }

        def initialize(val)
          super(TYPES[val] || val)
        end
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

    end
  end
end
