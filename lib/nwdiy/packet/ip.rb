#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# 使いかたは ipv4.rb あるいは ipv6.rb をご参照ください
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
