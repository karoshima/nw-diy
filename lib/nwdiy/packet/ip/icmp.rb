#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

class NwDiy
  class Packet
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
        else
          raise InvalidData.new(pkt)
        end
      end

      ################################################################
      # 各フィールドの値
      ################################################################

      attr_accessor :code
      attr_reader :type, :cksum

      def type=(val)
        @type = val
        self.data = @data
      end

      def data=(val)
        # 代入されたら @proto の値も変わる
        # 逆に val の型が不明なら、@proto に沿って @data の型が変わる
        dtype = self.class.class2id(val)
        if dtype
          @type = dtype
          @data = val
          return
        end
        @data = self.class.id2class(@type).cast(val)
      end

      ################################################################
      # 設定されたデータを元に、設定されてないデータを補完する
      def compile(overwrite = false)
        # 最後にチェックサムを計算する (TBD)
        @cksum or @cksum = 0
        self
      end

      ################################################################
      # その他の諸々
      def to_pkt
        self.compile
        @type.htob8 + @code.htob8 + @cksum.htob16 + @data.to_pkt
      end

      def bytesize
        self.compile
        4 + @data.bytesize
      end

      def to_s
        "type=#@type code=#@code #@data"
      end
    end
  end
end
