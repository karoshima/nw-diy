#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2018 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# with Apache-2 license.  check /LICENSE please.
################################################################
# Nwdiy::Func::VLAN
#    VLAN class
# Nwdiy::Func::Ethernet
#    Nwdiy::Func::Ethernet under Nwdiy::Func::VLAN
################################################################

module Nwdiy
  module Func

    ################################################################
    # create an VLAN instance

    class VLAN < Ethernet
    end

    # create an VLAN from the Ethernet
    class Ethernet
      protect
      def vlan_type(type, name)
        vl = VLAN.new(self.to_s + ":" + name)
        vl.type = type
        vl.lower = self
        self.upper[type] = vl
      end
      public
      def vlan
        self.vlan_type(0x8100, "VLAN")
      end
    end

    class VLAN
      attr_accessor :type
      def lower=(instance)
        if instance
          @lower_instance = instance
          self.thread_start
        else
          self.thread_stop
          @lower_instance = nil
        end
      end
    end

    class VLAN

      # close the instance (method override)
      protected
      def close_lower
        # do not close lower instance
        # (lower ethernet has many upper layers)
      end

      ################################################################
      # MAC address configuration (method override)
      protected
      def addr_init
        # my address
        @addr = nil
        # my joined group address
        @join = Hash.new
      end

