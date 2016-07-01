#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require 'nwdiy/packet/ip/icmp'

module NwDiy
  module Packet
    module IP
      class ICMP4 < ICMP
        # ほとんどは icmp.rb にある
        @@kt = KlassType.new({ ICMP::EchoRequest => 8,
                               ICMP::EchoReply => 0 })
        def data=(val)
          super(@@kt, val)
        end
        def to_s
          "[ICMP #{super}]"
        end
      end
    end
  end
end
