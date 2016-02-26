#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require_relative '../../nwdiy'

require 'nwdiy/util'

class NWDIY
  class PKT
    class MAC

      # バイナリ (6byte), String, NWDIY::PKT::MAC を元に MAC アドレスを生成する
      def initialize(mac = nil)
        case mac
        when String
          if (mac.bytesize == 6)
            @addr = mac
          else
            match = /(\h\h?):(\h\h?):(\h\h?):(\h\h?):(\h\h?):(\h\h?)/.match(mac)
            match or
              match = /(\h\h?)-(\h\h?)-(\h\h?)-(\h\h?)-(\h\h?)-(\h\h?)/.match(mac)
            match or
              match = /(\h\h?)\.(\h\h?)\.(\h\h?)\.(\h\h?)\.(\h\h?)\.(\h\h?)/.match(mac)
            match or
              raise ArgumentError.new("invalid MAC addr: #{mac}");
            @addr = match[1..6].map{|h|h.hex}.pack('C6')
          end
        when NWDIY::PKT::MAC
          @addr = mac.to_pkt
        when nil
          @addr = [0,0,0,0,0,0].pack('C6');
        else
          raise ArgumentError.new("invalid MAC addr: #{mac}");
        end
      end

      # パケットに埋め込むデータ
      def to_pkt
        @addr
      end

      # MAC の文字列表現
      def to_s
        @addr.unpack('C6').map{|h|sprintf('%02x',h)}.join(':')
      end

    end
  end
end
