#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require_relative '../nwdiy'

class NWDIY
  class PKT

    ################################################################
    # NWDIY::PKT に必須なメソッド

    # def to_pkt
    #   パケットデータである String を出力する
    # end

    # def to_s
    #   パケットを可視化する
    # end

    ################################################################
    # 最初に必要な NWDIY::PKT の子クラスを下記に定義しておく
    autoload(:Binary,   'nwdiy/packet/binary')
    autoload(:Ethernet, 'nwdiy/packet/ethernet')

    ################################################################
    # エラー関連
    class TooShort < Exception
    end
    class TooLong < Exception
    end
    class InvalidData < Exception
    end
  end

end
