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
          @txt = ''
          @bin.unpack('N*a*').each do |val|
            if val.kind_of?(Integer)
              @txt += '%08x ' % val
            else
              val.each_byte {|c| @txt += sprintf('%02x', c) }
            end
          end
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
