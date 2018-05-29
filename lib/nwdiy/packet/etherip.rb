#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2018 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# OSS with Apache License 2.0
# look at ./LICENSE
###################n#############################################
# Nwdiy::Packet::EtherIP is EtherIP packet
# you can chec spec at spec/nwdiy/packet/etherip_spec.rb.
################################################################

class Nwdiy::Packet::EtherIP < Nwdiy::Packet
  def_head :uint16, :reserved
  def_body :data

  def initialize(seed=nil)
    super(seed, {reserved: 0x1000})
  end

  def version
    @nwdiy_field[:reserved] >> 12
  end
  def version=(seed)
    @nwdiy_field[:reserved] = (seed & 0xf) << 12
  end

  def data=(seed)
    case seed
    when String
      @nwdiy_field[:data] = Nwdiy::Packet::Ethernet.new(seed)
    when Nwdiy::Packet::Ethernet
      @nwdiy_field[:data] = seed
    else
      raise "Unknown packet #{seed}"
    end
  end

  def inspect
    sprintf("[EtherIP %s]", data ? data.inspect : "(null)")
  end
end
