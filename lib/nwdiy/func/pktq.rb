#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2018 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# with Apache-2 license.  check /LICENSE please.
################################################################
# packet queue
#    like Thread::SizedQueue. diffs are below.
#    - do not block on queue full, drop the oldest pkt instead.
################################################################

module Nwdiy
  module Func
    class PktQueue < Thread::Queue

      MAXQLEN = 16
      
      def initialize(max = MAXQLEN)
        super()
        @max = max
        @cutter = Thread.new do
          loop do
            sleep 0.1
            return if self.closed?
            while @max < self.size do
              self.pop # drop the oldest one
            end
          end
        end
      end

      attr_accessor :max

      def close
        super
        @cutter.kill
        @cutter = nil
      end
    end
  end
end 
