#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################

class NWDIY
  class PKT

    autoload(:UINT8,  'nwdiy/packet/uint8')
    autoload(:TCP,    'nwdiy/packet/ip/udp')
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
          self.version = pkt[0]
          pkt.bytesize >= 20 or
            raise NWDIY::PKT::TooShort.new("packet TOO short for IPv4: #{pkt.dump}")
          self.hlen = pkt[0]
          (pkt.bytesize >= self.hlen) or
            raise NWDIY::PKT::TooShort.new("packet TOO short for IPv4: #{pkt.dump}")
          self.tos = pkt[1]
          self.length = pkt[2..3]
          self.id = pkt[4..5]
          self.fragment = pkt[6..7]
          self.ttl = pkt[8]
          self.protocol = pkt[9]
          self.checksum = pkt[10..11]
          self.src = pkt[12..15]
          self.dst = pkt[16..19]
          self.option = pkt[20, self.hlen*4-20]
          pkt[0, self.hlen*4] = ''
          self.data = pkt;
        when Hash
          self.version = pkt[:version] || 4
          self.hlen = pkt[:hlen] || 5
          self.tos = pkt[:tos] if pkt[:tos]
          self.length = pkt[:length] if pkt[:length]
          self.id = pkt[:id] if pkt[:id]
          self.fragment = pkt[:fragment] if pkt[:fragment]
          self.ttl = pkt[:ttl] || 64
          self.protocol = pkt[:protocol] if pkt[:protocol]
          self.checksum = pkt[:checksum] if pkt[:checksum]
          self.src = pkt[:src] if pkt[:src]
          self.dst = pkt[:dst] if pkt[:dst]
          self.option = pkt[:option] if pkt[:option]
          self.data = pkt[:data] if pkt[:data]
        when nil
          self.version = 4
          self.hlen = 5
          self.tos = 0
          self.id = 0
          self.fragment = 0
          self.ttl = 64
          self.protocol = 0
          self.checksum = 0
          self.src = "\0\0\0\0"
          self.dst = "\0\0\0\0"
          self.option = ""
          self.data = nil
        else
          raise InvalidData.new("not IPv4 packet: #{pkt}")
        end
      end

      ################################################################
      # 各フィールドの値の操作
      ################################################################
      # バージョン
      def version=(val)
        case val
        when Integer
          @version = val
          when String
          val.bytesize == 1 or
            raise TooLong.new("not IPv4 version: #{val}")
          @version = val.unpack('C')[0] >> 4
          @version == 4 or
            raise InvalidData.new("not IPV4 version: #{val}")
        else
          raise Invaliddata.new("not IPv4 version: #{val}")
        end
      end
      def version
        @version
      end

      ################
      # ヘッダ長
      def hlen=(val)
        oldhlen = @hlen
        case val
        when Integer
          @hlen = val
        when String
          val.bytesize == 1 or
            raise TooLong("not IPv4 header length: #{val}")
          @hlen = val.unpack('C')[0] >> 4
        else
          raise InvalidData.new("not IPv4 header legnth: #{val}")
        end
        @hlen >= 5 or
        # ヘッダ長が変わったら、option とデータの境目も変わる
        # @len の更新に合わせて、再パースする
        if @hlen != oldhlen && @opt && @data
          pkt = @opt.to_pkt + @data.to_pkt
          self.option = pkt[0, self.hlen*4-20]
          pkt[0, self.hlen*4-20] = ''
          self.data = pkt
        end
      end
      def hlen
        @hlen
      end

      ################
      # ToS
      def tos=(val)
        @tos = NWDIY::PKT::UINT8.new(val)
      end
      def tos
        @tos.to_i
      end

      ################
      # length
      def length=(val)
      end
      def length
        @hlen * 4 + (@data ? @data.length : 0)
      end

      ################
      # id
      def id=(val)
        @id = NWDIY::PKT::UINT16.new(val)
      end
      def id
        @id.to_i
      end

      ################
      # fragment
      def fragment=(val)
        @frag = NWDIY::PKT::UINT16.new(val)
      end
      def fragment
        @frag
      end
      def donotfragment=(bool)
        if bool
          @frag |= 0x0400
        else
          @frag &= ~0x0400
        end
      end
      def donotfragment
        (@frag & 0x0400) ? true : false
      end
      def morefrag=(bool)
        if bool
          @frag |= 0x0200
        else
          @frag &= ~0x0200
        end
      end
      def morefrag
        (@frag & 0x0200) ? true : false
      end
      def fragoffset=(val)
        @frag = (@frag & 0x0600) | (val & 0x1fff)
      end
      def fragoffset
        @frag & 0x1fff
      end

      ################
      # ttl
      def ttl=(val)
        @ttl = NWDIY::PKT::UINT8.new(val)
      end
      def ttl
        @ttl
      end

      ################
      # protocol
      def protocol=(val)
        val = resolv('/etc/protocols', val, :to_i)
        @proto = NWDIY::PKT::UINT8.new(val)
        # data 部は、型が変わるならフォーマット適用やり直し
        (@data && @data.class != self.dataKlass) and
          self.data = @data.to_pkt
      end
      def protocol
        @proto
      end

      ################
      # checksum
      def checksum=(val)
        @cksum = val ? NWDIY::PKT::UINT16.new(val) : nil
      end
      def checksum
        @cksum and return @cksum
        raise NotImplementedError.new('chotto matte yo!')
      end

      ################
      # IP addr
      def src=(val)
        @src = NWDIY::PKT::IPv4Addr.new(val)
      end
      def src
        @src
      end
      def dst=(val)
        @dst = NWDIY::PKT::IPv4Addr.new(val)
      end
      def dst
        @dst
      end

      ################
      # option
      def option=(val)
      end
      def option
        nil
      end

      ################
      # データ
      def dataKlass
        # (autoload が効くように、配列やハッシュにせずコードで列挙する)
        case @type
        when  1 then NWDIY::PKT::ICMP4
        when  6 then NWDIY::PKT::TCP
        when 17 then NWDIY::PKT::UDP
        else         NWDIY::PKT::Binary
        end
      end
      def data=(val)
        @data = nil
        case val
        when nil then return
        #when NWDIY::PKT::ICMP4 then @proto =  1
        #when NWDIY::PKT::TCP   then @proto =  6
        #when NWDIY::PKT::UDP   then @proto = 11
        else val = self.dataKlass.new(val)
        end
        @data = val
      end
      def data
        @data
      end

      ################################################################
      # その他の諸々
      def to_s
        "[IPv4 version=#{self.version} headerLen=#{self.hlen} ToS=#{self.tos} totalLength=#{self.length} id=${'%02x'%self.id} DNF=${self.donotfragment} more=#{self.morefrag} offset=${self.fragoffset} ttl=#{self.ttl} protocol=#{self.protocol} checksum=#{'%04x'%self.checksum} src=#{self.src} dst=#{self.dst} option=#{self.option} data=#{self.data}]"
      end
      def to_pkt
        ""
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
  end
end
