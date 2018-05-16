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
        @mutex = Mutex.new
      end

      attr_accessor :max

      def <<(value)
        @mutex.lock
        super
        while @max < self.length
          self.pop
        end
        @mutex.unlock
      end
      alias :enq :<<
      alias :push :<<

    end
  end
end 
