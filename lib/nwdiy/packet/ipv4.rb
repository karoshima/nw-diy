#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

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
          self.vhl = pkt[0].unpack('C')[0]
          self.tos = pkt[1]
          self.length = pkt[2..3]
          self.id = pkt[4..5]
          self.offset = pkt[6..7]
          self.ttl = pkt[8]
          self.protocol = pkt[9]
          self.checksum = pkt[10..11]
          self.src = pkt[12..15]
          self.dst = pkt[16..19]
          self.option = pkt[20..self.hlen]
          pkt[0..self.hlen] = ''
          self.data = pkt
        when nil
          @option = ''
        else
          raise InvalidData.new(pkt)
        end
      end

      ################################################################
      # 各フィールドの値
      ################################################################

      def vhl=(val)
        @vhl = pkt[0].btohc
      end
      def version
        @vhl >> 4
      end
      def hlen
        (@vhl & 0xf) * 4
      end

      def tos=(val)
        @tos = val.btoh8
      end
      attr_reader :tos

      def length=(val)
        @length = val.btoh16
      end
      attr_reader :length

      def id=(val)
        @id = val.btoh16
      end
      attr_reader :id

      def offset=(val)
        @offset = val.btoh16
      end
      def df
        !!(@offset & 0x4000)
      end
      def more
        !!(@offset & 0x2000)
      end
      def fragmentOffset
        @offset & 0x1fff
      end

      def ttl=(val)
        @ttl = val.btoh8
      end
      attr_reader :ttl

      def proto=(val)
        @protocol = val.htob8
      end
      attr_reader :proto

      def cksum=(val)
        @cksum = val.btoh16
      end
      attr_reader :cksum

      def src=(val)
        @src = NWDIY::PKT::IPv4Addr.new(val)
      end
      attr_reader :src

      def dst=(val)
        @dst = NWDIY::PKT::IPv4Addr.new(val)
      end
      attr_reader :dst

      def option=(val)
        @option = ''
      end
      attr_reader :option

      attr_accessor :data

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
          @length - self.hlen < @data.bytesize and
            raise TooLong.new("IP data too long")
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
          when  1 then @data = ICMP4.new(@data).compile
          when  6 then @data = TCP.new(@data).compile
          when 17 then @data = UDP.new(@data).compile
          else         @data = Binary.new(@data)
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
        "[IPv4 version=#{self.version} headerLen=#{self.hlen} ToS=#@tos length=#@length id="+sprintf('%02x',self.id)+"#{self.df&&' DF'}#{self.more&&' more'}offset=#{self.fragmentOffset} ttl=#@ttl protocol=#@protocol checksum="+sprintf('%04x',self.checksum)+" src=#@src dst=#@dst option=#@option data=#@data]"
      end
    end

    class IPv4Addr
      def initialize(addr = nil)
        case addr
        when String
          if addr.bytesize == 4
            @addr = addr
          else
            match = /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/.match(addr)
            match or
              raise ArgumentError.new("invalid IPv4 adr: #{addr}")
            addr = match[1..4].map {|m| m.to_i}
            addr.each do |a|
              (0<=a && a<=255) or
                raise ArgumentError.new("invalid IPv4 adr: #{addr}")
            end
            @addr = addr.pack('C4')
          end
        when NWDIY::PKT::IPv4Addr
          @addr = addr.to_pkt
        when nil
          @addr = [0,0,0,0].pack('C4')
        else
          raise ArgumentError.new("invalid IPv4 adr: #{addr}")
        end
      end

      # パケットに埋め込むデータ
      def to_pkt
        @addr
      end

      # 文字列表現
      def to_s
        @addr.unpack('C4').map {|a| a.to_s }.join('.')
      end

    end

    class ARP
    end
  end
end
