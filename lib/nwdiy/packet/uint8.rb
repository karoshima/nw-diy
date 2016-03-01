#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require_relative '../../nwdiy'

class NWDIY
  class PKT
    class UINT8
      include Comparable

      def initialize(val)
        case val
        when Integer
          @value = val
        when String
          val.bytesize == 1 or
            raise TooLong.new("not uint8_t: too long: #{val}");
          @value = (val.unpack('C')[0])
        else
          raise InvalidData.new("not uint8_t: unavailable: #{val}");
        end
      end

      def to_i
        @value
      end
      def <=>(other)
        @value <=> other
      end

      def to_pkt
        [@value].pack('C')
      end
      def to_s
        sprintf('%02x', @value)
      end
    end
  end
end
