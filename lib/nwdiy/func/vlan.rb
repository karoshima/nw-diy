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

    class VLAN < Ethernet
    end

    ################################################################
    # create an VLAN instance

    # create an VLAN from the Ethernet
    class Ethernet
      protected
      def vlan_type(type, name)
        return self[type] if self[type]
        vl = VLAN.new(self.to_s + ":" + name)
        vl.type = type
        vl.lower = self
        return self[type] = vl
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
          @instance_lower = instance
          self.thread_start
        else
          self.thread_stop
          @instance_lower = nil
        end
      end

      # close the instance (method override)
      protected
      def close_lower
        # do not close lower instance
        # (lower ethernet has many upper layers)
      end
    end

    ################################################################
    # create VLANID (VLAN[x]) instance from a VLAN

    class VLAN
      def newid(id)
        self[id] = VLANID.new(self, id)
      end
    end
    class VLANID < Ethernet
      def initialize(vlan, id)
        super("[#{id}]")
        @vlanid = id
        self.lower = vlan
      end
    end

    ################################################################
    # MAC address configuration (method override)
    class VLAN
      protected
      def addr_default
        nil
      end
    end
    class VLANID
      protected
      def addr_default
        nil
      end
    end

    ################################################################
    # packet flow

    class VLANID
      # overwrite one of flowdown functions
      protected
      def capsule(pkt)
        vlan = Nwdiy::Packet::VLAN.new(vid: @vlanid, data: pkt.data)
        pkt.data = vlan
        return pkt
      end
    end

    # overwrite the flowup function
    class VLAN
      public
      def upper_for_packet(pkt)
        return nil unless pkt.kind_of?(Nwdiy::Packet::Ethernet)
        return nil unless pkt.data.kind_of?(Nwdiy::Packet::VLAN)
        return self[pkt.data.vid]
      end
    end
    class VLANID
      def push_others(pkt, lower=[])
        raise Errno::EINVAL unless pkt.kind_of?(Nwdiy::Packet::Ethernet)
        raise Errno::EINVAL unless pkt.data.kind_of?(Nwdiy::Packet::VLAN)
        vlan = pkt.data
        pkt.data = vlan.data
        @upq_lower.push([pkt, lower + [vlan]])
      end
    end

  end
end
