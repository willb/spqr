#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'spqr/spqr'
require 'spqr/app'
require 'example-apps'

klasses = ARGV.map {|klass| Kernel.const_get(klass)}

DEBUG = (::ENV["SPQR_TESTS_DEBUG"] and ::ENV["SPQR_TESTS_DEBUG"].downcase == "yes")

app = SPQR::App.new(:loglevel => (DEBUG ? :debug : :fatal), :appname=>"#{klasses.join("")}[#{Process.pid}]")
app.register *klasses
while true
  app.main rescue nil
end

sleep