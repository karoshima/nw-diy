#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# ruby で使う ip link コマンド

require 'pp'

class NWDIY
  class IPLINK
    def initialize
      @index = []
      @name = {}
      `ip link`.gsub(/\n\s+/, ' ').lines.each do |line|
        dummy, index, name = *(/^(\d+): ([^:]+):/.match(line))
        index or next
        ifa = NWDIY::IPLINK::IFA.new(index, name)
        @index[index.to_i] = ifa;
        @name[name] = ifa;
        ifa.parse_link(line)
      end
      `ip addr`.gsub(/\n\s+/, ' ').lines.each do |line|
        dummy, index = *(/^(\d+):/.match(line))
        index or next
        ifa = @index[index.to_i]
        ifa.parse_addr(line)
      end
    end

    def length
      @index.length
    end
    def [](key)
      key.kind_of?(Integer) ? @index[key] : @name[key]
    end

    class IFA
      attr_reader :index, :name, :flags, :mtu, :mtu, :state, :type, :mac
      def initialize(index, name)
        @index, @name = index, name
      end

      def parse_link(line)
        dummy, flags, @mtu, @state = *(/<([^<>]*)> mtu (\d+)/.match(line))
        dummy, @type, @mac = *(/link\/(\w+) ([\h:]+)/.match(line))
        @flags = flags.split(/,/)
      end

      def parse_addr(line)
        @ipv4 = line.scan(/inet ([\d\.]+)\/(\d+)/).map{|ifa| {addr: ifa[0], mask: ifa[1]}}
        @ipv6 = line.scan(/inet6 ([\h\:]+)\/(\d+)/).map{|ifa| {addr: ifa[0], mask: ifa[1]}}
      end

      def addr(type = '')
        type.match(/ipv4/i) and
          return @ipv4
        type.match(/ipv6/i) and
          return @ipv6
        type.match(/./) and
          raise ArgumentError.new('"ipv4" or "ipv6" are available.');
        return @ipv4 + @ipv6
      end
    end
  end
end
