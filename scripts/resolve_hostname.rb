#!/usr/bin/env ruby

require 'resolv'

address = ARGV[0]
puts Resolv.getaddress(address)
