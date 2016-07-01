#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require_relative '../../nwdiy'

require 'nwdiy/util'

module NwDiy
  module Packet

    # 型がよく分からない
    # なにかのバイナリデータ
    class Binary

      def initialize(pkt)
        super()
        pkt.instance_of?(String) or
          raise InvalidData, pkt
        @bin = pkt  # データそのもの
        @txt = nil  # self.to_s 表示用キャッシュ
      end

      def to_pkt
        @bin
      end
      def bytesize
        @bin.bytesize
      end

      def to_s
        unless @txt
          @txt = ''
          @bin[0..15].unpack('N*a*').each do |val|
            if val.kind_of?(Integer)
              @txt += '%08x ' % val
            else
              val.each_byte {|c| @txt += sprintf('%02x', c) }
            end
          end
        end
        @txt
      end

    end
  end
end
