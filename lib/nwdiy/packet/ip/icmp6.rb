#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require 'nwdiy/packet/ip/icmp'

module NwDiy
  module Packet
    module IP
      class ICMP6 < ICMP
        # ほとんどは icmp.rb にある
        @@kt = KlassType.new({ ICMP::EchoRequest => 128,
                               ICMP::EchoReply => 129 })
        def data=(val)
          super(@@kt, val)
        end
        def to_s
          "[ICMPv6 #{super}]"
        end
      end
    end
  end
end
