#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require 'nwdiy/packet/ip/icmp'

class NwDiy
  class Packet
    class ICMP4 < ICMP
      # ほとんどは icmp.rb にある
      def to_s
        "[ICMP #{super}]"
      end
    end
  end
end
