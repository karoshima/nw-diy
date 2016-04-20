#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

class NwDiy
  class Packet

    autoload(:TCP,    'nwdiy/packet/ip/tcp')
    autoload(:UDP,    'nwdiy/packet/ip/udp')
    autoload(:ICMP6,  'nwdiy/packet/ip/icmp6')

    class IPv6
      include NwDiy::Linux

      ################################################################
      # プロトコル番号とプロトコルクラスの対応表
      # (遅延初期化することで、使わないクラス配下のデータクラスまで
      #  無駄に読み込んでしまうことを防ぐ)
      @@kt = KlassType.new({ ICMP6 => 58 })

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
          pkt.bytesize >= 40 or
            raise TooShort.new(pkt)
          @vtf = pkt[0..3].btoh
          @length = pkt[4..5].btoh
          self.next = pkt[6].btoh
          @hlim = pkt[7].btoh
          @src = IPAddr.new_ntoh(pkt[8..23])
          @dst = IPAddr.new_ntoh(pkt[24..39])
          pkt[0..39] = ''
          self.data = pkt
        when nil
          @vtf = 0x60000000
        else
          raise InvalidData.new(pkt)
        end
      end

      ################################################################
      # 各フィールドの値
      ################################################################

      attr_accessor :hlim
      attr_reader :length, :next, :src, :dst

      def version
        (@vtf & 0xf0000000) >> 28
      end
      def tc
        (@vtf & 0x0ff00000) >> 20
      end
      def tc=(val)
        @vtf = (@vtf & 0xf00fffff) | ((val << 20) & 0x0ff00000)
      end
      def flow
        @vtf & 0x000fffff
      end
      def flow=(val)
        @vtf = (@vtf & 0xfff00000) | (val & 0x000fffff)
      end

      def next=(val)
        # 代入されたら @data の型も変わる
        @next = val
        @data and
          self.data = @data
      end

      def src=(val)
        @src = IPAddr.new(val, Socket::AF_INET6)
      end
      def dst=(val)
        @dst = IPAddr.new(val, Socket::AF_INET6)
      end

      def data=(val)
        # 代入されたら @length, @next の値も変わる
        # 逆に val の型が不明なら、@next に沿って @data の型が変わる
        dtype = @@kt.type(val)
        if dtype
          @next = dtype
          @data = val
        else
          @data = @@kt.klass(@next).cast(val)
        end
        @length = 40 + @data.bytesize
      end

      ################################################################
      # 設定されたデータを元に、設定されてないデータを補完する
      def compile(overwrite = false)
        @data or
          raise TooShort.new('no data')
        unless self.version == 6
          if overwrite
            @vtf = 0x60000000 | (@vtf & 0x0fffffff)
          else
            raise InvalidData.new("Invalid version: #{self.version}")
          end
        end

        # @length 確認
        if 40 + @data.bytesize < @length
          if overwrite
            @length = 40 + @data.bytesize
          else
            raise TooShort.new("IP data too short")
          end
        end

        # 最後にチェックサムを計算する (TBD)
        @cksum or @cksum = 0
        self
      end

      ################################################################
      # その他の諸々
      def to_pkt
        self.compile
        @vtf.htob32 + @length.htob16 + @nh.htob8 + @hlim.htob8 +
          @src.hton + @dst.hton + @data.to_pkt
      end

      def bytesize
        self.compile
        @length
      end

      def to_s
        name = resolv('/etc/protocols', @next)
        name.kind_of?(Array) and
          name = name[0]
        "[IPv6 #@src > #@dst #{name} #@data]"
      end
    end
  end
end
