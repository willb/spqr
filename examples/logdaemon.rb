#!/usr/bin/env ruby

# This is a simple logging service that operates over QMF.  It is very similar
# to logservice.rb, except it makes QMF events for log events instead of
# database records.  LogEventService has the same API as LogService; LogEvent
# is a SPQR event class.  See the comments for details on how to use QMF events.

require 'spqr/spqr'
require 'spqr/app'

class LogEventService
  include SPQR::Manageable

  [:debug, :warn, :info, :error].each do |name|
    define_method name do |msg|
      # Construct a new event by passing arguments to .new in the order that they were declared
      ev = LogEvent.new(Time.now.utc.to_i * 1000000000, "#{name.to_s.upcase}", msg.dup)
      
      # You can also set arguments of an event object individually, like this:
      # ev = LogEvent.new
      # ev.l_when = Time.now
      # ev.severity = name.to_s.upcase
      # ev.msg = msg.dup
      
      # Once all of the arguments are set, raise the event:
      ev.bang!
    end
    
    expose name do |args|
      args.declare :msg, :lstr, :in
    end
  end

  def self.find_all
    @singleton ||= LogEventService.new
    [@singleton]
  end

  def self.find_by_id(i)
    @singleton ||= LogEventService.new
  end

  qmf_package_name :examples
  qmf_class_name :LogEventService
end

class LogEvent
  # To declare an event class, include SPQR::Raiseable
  include ::SPQR::Raiseable
  
  # Declare arguments with their name, type, and (optional) description
  arg :l_when, :absTime, "When the event happened"
  arg :severity, :sstr, "Event severity:  DEBUG, WARN, INFO, or ERROR"
  arg :msg, :lstr, "Log message"

  # Declare metadata as appropriate
  qmf_package_name :examples
  qmf_class_name :LogEvent
end

app = SPQR::App.new(:loglevel => :debug)

# Event classes must be registered just like object classes
app.register LogEventService, LogEvent

app.main
