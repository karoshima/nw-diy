#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require 'ipaddr'
require 'nwdiy/packet'

module NwDiy
  module Packet
    module IP
      include Packet

      autoload(:TCP,    'nwdiy/packet/ip/tcp')
      autoload(:UDP,    'nwdiy/packet/ip/udp')
      autoload(:ICMP4,  'nwdiy/packet/ip/icmp4')
      autoload(:OSPFv2, 'nwdiy/packet/ip/ospf')
      autoload(:ICMP6,  'nwdiy/packet/ip/icmp6')

    end
  end
end
