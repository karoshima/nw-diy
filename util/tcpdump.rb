#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# ruby で綴る VM interface のための、tcpdump

require_relative '../lib/nwdiy'

require 'nwdiy/interface'

ifp = NwDiy::Interface.new(ARGV[0])
loop do
  puts ifp.recv
end
