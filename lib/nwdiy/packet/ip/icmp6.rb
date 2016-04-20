#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require 'nwdiy/packet/ip/icmp'

class NwDiy
  class Packet
    class ICMP6 < ICMP
      # ほとんどは icmp.rb にある
      def to_s
        "[ICMPv6 #{super}]"
      end
    end
  end
end
