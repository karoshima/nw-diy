#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require_relative '../../nwdiy'

require 'nwdiy/util'

class NWDIY
  class PKT

    # 型がよく分からない
    # なにかのバイナリデータ
    class Binary

      def initialize(pkt = '')
        @bin = pkt
      end

      def to_pkt
        @bin
      end

      def to_s
        unless @txt
          #@txt = @bin.scan(/.{1,4}/m).map(&:dump).map{|s|s.gsub(/^"|"$/m,'')}.join(' ')
          @txt = @bin.scan(/.{1,4}/m).map{|s|s.unpack('C*').map{|c|sprintf("%02x",c)}.join}.join(' ')
        end
        @txt
      end

      def self.kind
        'Binary'
      end

      def length
        @bin.bytesize
      end
    end
  end
end
