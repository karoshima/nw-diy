#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# ruby で綴る VM interface

require "socket"

class NWDIY
  class IFP
    # new 引数は DWDIY::VM.new の引数そのままハッシュ化したもの
    def self.create(ifp)
      case ifp[:type]
      when :pcap then return self.pcap(ifp[:name])
      when :tap  then return self.tap(ifp[:name])
      when :file then return self.file(ifp[:name])
      else
        raise "unknown type #{ifp[:type]}"
      end
    end

    def self.pcap(ifp)
      raise "not implemented yet"
    end

    def self.tap(ifp)
      raise "not implemented yet"
    end

    def self.file(path)
      path = "/tmp/#{path}"
      begin
        return UNIXSocket.new(path)
      rescue Errno::ECONNREFUSED
        File.unlink(path)
      rescue Errno::ENOENT
      end
      return UNIXServer.new(path)
    end
  end
end
