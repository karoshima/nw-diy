#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

require 'ipaddr'

class NWDIY
  class PKT

    autoload(:TCP,    'nwdiy/packet/ip/tcp')
    autoload(:UDP,    'nwdiy/packet/ip/udp')
    autoload(:ICMP4,  'nwdiy/packet/ip/icmp4')
    autoload(:OSPFv2, 'nwdiy/packet/ip/ospf')

    class IPv4
      include NWDIY::Linux

      ################################################################
      # パケット生成
      ################################################################
      # 受信データあるいはハッシュデータからパケットを作る
      def initialize(pkt = nil)
        case pkt
        when String
          pkt.bytesize > 20 or
            raise TooShort.new(pkt)
          @vhl = pkt[0].btoh
          @tos = pkt[1].btoh
          @length = pkt[2..3].btoh
          @id = pkt[4..5].btoh
          @offset = pkt[6..7].btoh
          @ttl = pkt[8].btoh
          @proto = pkt[9].btoh
          @cksum = pkt[10..11].btoh
          @src = IPAddr.new_ntoh(pkt[12..15])
          @dst = IPAddr.new_ntoh(pkt[16..19])
          @option = pkt[20..(self.hlen-1)]
          pkt[0..(self.hlen-1)] = ''
          self.data = pkt
          self.compile
        when nil
        else
          raise InvalidData.new(pkt)
        end
      end

      ################################################################
      # 各フィールドの値
      ################################################################

      def version
        @vhl >> 4
      end
      def hlen
        (@vhl & 0xf) * 4
      end

      attr_accessor :tos, :length, :id, :ttl, :proto, :cksum, :src, :dst, :option, :data

      def df
        !!(@offset & 0x4000)
      end
      def more
        !!(@offset & 0x2000)
      end
      def fragmentOffset
        @offset & 0x1fff
      end

      ################################################################
      # 設定されたデータを元に、設定されてないデータを補完する
      def compile(overwrite = false)
        # data 確認
        @data && @data.bytesize > 0 or
          raise TooShort.new("IP data is necessary")

        # @vhl 確認
        begin
          self.version == 4 or
            raise InvalidData.new("Invalid Version: #{self.version}")
          self.hlen >= 20 or
            raise InvalidData.new("Invalid Header length: #{self.hlen}")
          optlen = @option ? @option.bytesize : 0
          self.hlen - 20 < optlen and
            raise TooLong.new("IP option too long")
          self.hlen - 20 > optlen and
            raise TooShort.new("IP option too short")
        rescue => e
          if !@vhl or overwrite
            @vhl = 0x45 + (@option ? @option.bytesize / 4 : 0)
          else
            raise e
          end
        end

        # @length 確認
        begin
          #@length - self.hlen < @data.bytesize and
          #  raise TooLong.new("IP data too long")
          #不要なtrailerが付いちゃうケース散見される
          @length - self.hlen > @data.bytesize and
            raise TooShort.new("IP data too short")
        rescue => e
          if !@length or overwrite
            @length = self.hlen + @data.bytesize
          else
            raise e
          end
        end

        # @proto 確認
        case @data
        when ICMP4 then klass =  1
        when TCP   then klass =  6
        when UDP   then klass = 17
        else            klass = nil
        end
        if klass
          if overwrite
            @proto = klass
          else
            raise InvalidData.new("proto:#{@proto} != data:#{@data.class}")
          end
        else
          case @proto
#          when  1 then @data = ICMP4.new(@data).compile
#          when  6 then @data = TCP.new(@data).compile
#          when 17 then @data = UDP.new(@data).compile
          when 89 then @data = Binary.create(@data)
          else         @data = Binary.create(@data)
          end
        end
        self
      end

      ################################################################
      # その他の諸々
      def to_pkt
        self.compile
        @vhl.htob8 + @tos.htob8 + @length.htob16 +
          @id.htob16 + @offset.htob16 +
          @ttl.htob8 + @proto.htob8 + @cksum.htob16 +
          @src.to_pkt + @dst.to_pkt + @option +
          @data.to_pkt
      end

      def bytesize
        self.compile
        @length
      end


      ################################################################
      # その他の諸々
      def to_s
        "[IPv4 #@src > #@dst #@proto #@data]"
      end
    end

    class ARP
    end
  end
end
