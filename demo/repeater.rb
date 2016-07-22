#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
#

require_relative '../textbook/2.1-repeater.rb'

vm = Repeater.new
vm.addif('north0')
vm.addif('south0')
vm.addif('east0')
vm.addif('west0')
vm.job
