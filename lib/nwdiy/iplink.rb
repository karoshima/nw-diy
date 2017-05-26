#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください
################################################################
# ruby で使う ip link コマンド

require_relative '../nwdiy'

module NwDiy
  class IpLink
    include Enumerable

    def initialize
      @index = []
      @name = {}
      begin
        `ip link`.gsub(/\n\s+/, ' ').lines.each do |line|
          dummy, index, name = *(/^(\d+): ([^:@]+)/.match(line))
          next unless index
          ifa = NwDiy::IpLink::IfAddr.new(index, name)
          @index[index.to_i] = ifa;
          @name[name] = ifa;
          ifa.parse_link(line)
        end
        `ip addr`.gsub(/\n\s+/, ' ').lines.each do |line|
          dummy, index = *(/^(\d+):/.match(line))
          next unless index
          ifa = @index[index.to_i]
          ifa.parse_addr(line)
        end
      rescue Errno::ENOENT
      end
    end

    def length
      @index.length
    end
    def [](key)
      return @index[key] if key.kind_of?(Integer)
      return @name[key] if key.kind_of?(String)
      return @index[key.to_i] if key.respond_to?(:to_i)
      return @index[key.to_s] if key.respond_to?(:to_s)
      nil
    end
    def each
      @index.each {|link| yield link}
    end

    class IfAddr
      include Comparable

      attr_reader :index, :name, :flags, :mtu, :state, :type, :mac
      def initialize(index, name)
        @index, @name = index.to_i, name
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

      def <=>(other)
        case other
        when String
          @name <=> other
        when Integer
          @index - other
        else
          nil
        end
      end
      def to_s
        @name
      end
      def to_i
        @index
      end
      def addr(type = '')
        return @ipv4 if type.match(/ipv4/i)
        return @ipv6 if type.match(/ipv6/i)
        raise ArgumentError.new('"ipv4" or "ipv6" are available.') if type.match(/./)
        return @ipv4 + @ipv6
      end
    end
  end
end
