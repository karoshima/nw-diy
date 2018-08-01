#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2018 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# with Apache-2 license.  check /LICENSE please.
################################################################
# Nwdiy::Func::EtherIP
#    Ethernet over IP interface class
# Nwdiy::Func::EtherIPReceiver
#    instance methods for instances under Nwdiy::Func::EtherIP
#    typically, IPv4 and IPv6
################################################################
# irb> ipv4.etherip(peer: "192.0.2.2")
#
#    (1) IPv4 instance creates EtherIP instance,
#        which handles IP proto 97 and peer nodes.
#    (2) @eip creates peer node 192.0.2.2.
#    (3) the new peer node creates Ethernet instance on it.
#    
################################################################

require 'thread'
require 'nwdiy/func/ethernet'

module Nwdiy
  module Func

    ################################################################
    # create an EtherIP instance

    class EtherIP

      IP_PROTO_ETHERIP = 97

      include Nwdiy::Func
      include Nwdiy::Debug

      def initialize(klass)
        name = 'EtherIP'
        debug(name)
        super(name)
        @addrClass = klass
        @node = Hash.new { |hash,key| hash[key] = EtherIPNode.new(self, key) }
      end
    end

    module EtherIPReceiver
      def etherip
        eip = self[EtherIP::IP_PROTO_ETHERIP]
        unless eip
          case self
          when Nwdiy::Func::IPv4
            klass = Nwdiy::Packet::IPv4Addr
          else
            raise "Unknown Function class #{self.class}"
          end
          eip = self[EtherIP::IP_PROTO_ETHERIP] = EtherIP.new(klass)
          eip.lower = self
        end
        return eip
      end
    end

    class IPv4
      include EtherIPReceiver
    end

    class EtherIP
      public
      def lower=(instance)
        if instance
          debug "@instance_lower = #{instance}"
          @instance_lower = instance
#          self.thread_start
        else
#          self.thread_stop
          @instance_lower = nil
        end
      end

      ################################################################
      # upper layers
      def [](addr)
        unless addr.kind_of?(@addrClass)
          addr = @addrClass.new(addr)
        end
        return @node[addr]
      end
    end

    ################################################################
    # create an EtherIP peer node instance

    class EtherIPNode < Ethernet

      def initialize(etherip, addr)
        name = "EtherIP(#{addr.inspect})"
        debug(name)
        super(name)
        @etherip = etherip
        @addr = addr
      end
    end
  end
end
