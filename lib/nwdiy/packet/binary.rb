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

      def self.cast(pkt = nil)
        pkt.kind_of?(self) and
          return pkt
        self.new(pkt.respond_to?(:to_pkt) ? pkt.to_pkt : pkt)
      end
      def initialize(pkt)
        @bin = pkt
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
