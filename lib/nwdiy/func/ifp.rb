#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################

class Nwdiy::Func::Ifp < Nwdiy::Func

  include Nwdiy::Debug
  #  debugging true

  autoload(:OS,       'nwdiy/func/ifp/os')
  autoload(:Ethernet, 'nwdiy/func/ifp/ethernet')

end
