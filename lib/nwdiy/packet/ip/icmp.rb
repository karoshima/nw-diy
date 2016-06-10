#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

module NwDiy
  module Packet
    module IP
      class ICMP

        ################################################################
        # プロトコル番号とプロトコルクラスの対応表

        ################################################################
        # パケット生成
        ################################################################
        def self.cast(pkt = nil)
          pkt.kind_of?(self) and
            return pkt
          self.new(pkt.respond_to?(:to_pkt) ? pkt.to_pkt : pkt)
        end

        # 受信データからパケットを作る
        def initialize(pkt = nil)
          case pkt
          when String
            pkt.bytesize >= 4 or
              raise TooShort.new(pkt)
            @type = pkt[0].btoh
            @code = pkt[1].btoh
            @cksum = pkt[2..3].btoh
            pkt[0..3] = ''
            self.data = pkt
          when nil
            @type = @code = @cksum = 0
            @data = Binary.new('')
          else
            raise InvalidData.new(pkt)
          end
        end

        ################################################################
        # 各フィールドの値
        ################################################################

        attr_accessor :code
        attr_reader :type, :cksum, :data

        def type=(val)
          @type = val
          self.data = @data
        end

        def data=(kt, val)
          # 代入されたら @proto の値も変わる
          # 逆に val の型が不明なら、@proto に沿って @data の型が変わる
          dtype = kt.type(val)
          dtype and
            @type = dtype
          @data = kt.klass(@type).cast(val)
        end

        ################################################################
        # その他の諸々
        def to_pkt
          @type.htob8 + @code.htob8 + @cksum.htob16 + @data.to_pkt
        end

        def bytesize
          4 + @data.bytesize
        end

        def to_s
          "type=#@type code=#@code #@data"
        end
      end
    end
  end
end
