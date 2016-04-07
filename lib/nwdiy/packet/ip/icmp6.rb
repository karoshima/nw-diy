#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require 'nwdiy/packet/ip/icmp'

class NWDIY
  class PKT
    class ICMP6 < ICMP
      # ほとんどは icmp.rb にある
      def self.clsid
        @@clsid and return @@clsid
        @@clsid = NWDIY::ClassId.new({})
      end
      def to_s
        "[ICMPv6 #{super}]"
      end
    end
  end
end
