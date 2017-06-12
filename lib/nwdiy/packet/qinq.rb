#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# 使いかたは vlan.rb をご参照ください
################################################################

module NwDiy
  module Packet

    autoload(:IPv4, 'nwdiy/packet/ipv4')
    autoload(:ARP,  'nwdiy/packet/arp')
    autoload(:IPv6, 'nwdiy/packet/ipv6')
    autoload(:VLAN, 'nwdiy/packet/vlan')

    class QinQ < NwDiy::Packet::VLAN
    end
  end
end
