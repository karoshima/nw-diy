#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require_relative '../../nwdiy'

class NWDIY
  class PKT
    class UINT16
      include Comparable

      def initialize(val)
        case val
        when Integer
          @value = val
        when String
          val.bytesize == 2 or
            raise TooLong.new("not uint16_t: too long: #{val}");
          @value = (val.unpack('n')[0])
        else
          raise InvalidData.new("not uint16_t: unavailable: #{val}");
        end
      end

      def to_i
        @value
      end
      def <=>(other)
        @value <=> other
      end
      def &(val)
        @value & val
      end

      def to_pkt
        [@value].pack('n')
      end
      def to_s
        sprintf('%04x', @value)
      end
    end
  end
end
