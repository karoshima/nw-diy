#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
#

require_relative '../textbook/2.1-repeater.rb'

vm = Repeater.new
vm.addif('north0')
vm.addif('south0')
vm.addif('east0')
vm.addif('west0')
vm.job
