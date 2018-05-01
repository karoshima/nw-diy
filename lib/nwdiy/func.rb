#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2018 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# with Apache-2 license.  check /LICENSE please.
################################################################
# top of NW-DIY functions.
################################################################

module Nwdiy
  module Func

    autoload(:Ethernet, 'nwdiy/func/ethernet')

    MAXQLEN = 16

    attr_accessor :to_s

    private
    def initialize(name)
      @to_s = name
      pktq_init
    end

    ################################################################
    # packet queue handler
    #   these functions are common for every instances.
    #   these functions may be overwritten for each sub-class.
    #
    # send(pkt)
    #    this is called from the upper layer.
    #    send a packet to the lower layer.
    #
    # pop
    #    this is called from the lower layer.
    #    get a packet to be sent to the lower layer.
    #
    # push(pkt)
    #    this is called from the lower layer.
    #    push a received packet from the lower layer.
    #
    # recv()
    #    this is called from the upper layer.
    #    get a received packet from the lower layer.
    ################################################################

    def pktq_init
      @pktq = Hash.new
      @pktq[:up] = Queue.new
      @pktq[:down] = Queue.new
    end

    def enque_pkt(dir, pkt)
      @pktq[dir].push(pkt)
      if MAXQLEN < @pktq[dir].length
        deque_pkt(dir)
      end
    end
    def deque_pkt(dir)
      @pktq[dir].pop
    end

    public

    # upper layer can send down a packet
    def send(pkt)
      enque_pkt(:down, pkt)
    end

    # upper layer can recv up a packet
    def recv
      deque_pkt(:up)
    end

    # lower layer can send up a packet
    def push(pkt)
      enque_pkt(:up, pkt)
    end

    # lower layer can recv down a packet
    def pop
      deque_pkt(:down)
    end

  end
end
