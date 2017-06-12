#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# 使いかたは icmp.rb をご参照ください
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
