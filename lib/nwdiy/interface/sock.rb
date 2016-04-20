#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# ruby で綴る、AF_UNIX による VM interface

require_relative '../../nwdiy'

class NwDiy
  class Interface
    class Sock
      include NwDiy::Linux

      def initialize(name)
      end

    end
  end
end
