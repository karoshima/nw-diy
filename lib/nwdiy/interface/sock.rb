#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# ruby で綴る、AF_UNIX による VM interface

require_relative '../../nwdiy'

class NWDIY
  class IFP
    class Sock
      include NWDIY::Linux

      def initialize(name)
      end

    end
  end
end
