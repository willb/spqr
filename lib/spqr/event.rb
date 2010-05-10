# SPQR:  Schema Processor for QMF/Ruby agents
#
# Manageable object mixin and support classes.
#
# Copyright (c) 2009--2010 Red Hat, Inc.
#
# Author:  William Benton (willb@redhat.com)
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0

module SPQR
  class EventMeta < Struct.new(:package, :classname, :args, :severity)
    def initialize(*a)
      super *a
      self.args ||= []
      self.severity ||= :alert
    end
  end

  class EventArgMeta < Struct.new(:name, :kind, :description, :options)
    def initialize(*a)
      super *a
      self.options = ((!self.options && {}) || self.options.dup)
    end
  end
  
  module Raiseable
    module ClassMixins
      include ::SPQR::Util
      
      def arg(name, kind, description=nil, options=nil)
        @spqr_event_meta ||= EventMeta.new
        @spqr_event_meta.args << EventArgMeta.new(name.to_sym,kind,description,options)
        attr_accessor name.to_sym
        attr_setters << "#{name.to_s}="
      end
      
      def spqr_meta
        @spqr_event_meta ||= EventMeta.new
        
      end
      
      def log=(logger)
        @spqr_log = logger
      end

      def log
        @spqr_log || ::SPQR::Sink.new
      end

      def app=(app)
        @spqr_app = app
      end

      def app
        @spqr_app
      end
      
      def attr_setters
        @attr_setters ||= []
        @attr_setters
      end
      
      def schematize
        severity = get_xml_constant(spqr_meta.severity.to_s, ::SPQR::XmlConstants::Severity)
        
        @spqr_schema_class = Qmf::SchemaEventClass.new(spqr_meta.package.to_s, spqr_meta.classname.to_s, severity)
        
        spqr_meta.args.each do |arg|
          encode_argument(arg, @spqr_schema_class)
        end
        
        @spqr_schema_class
      end
      
      def schema_class
        @spqr_schema_class
      end
      
      def qmf_package_name(nm)
        spqr_meta.package = nm
      end

      def qmf_class_name(nm)
        spqr_meta.classname = nm
      end
      
      def qmf_severity(sev)
        raise ArgumentError.new("Invalid event severity '#{sev.inspect}'") unless ::SPQR::XmlConstants::Severity.keys.include? sev.to_s
        spqr_meta.severity = sev
      end
      
      alias severity qmf_severity
    end
    
    module InstanceMixins
      def initialize(*args)
        if args.size > self.class.attr_setters.size
          msg = "Too many arguments (max #{self.class.attr_setters.size}) to #{self.class.name}#initialize:  #{args}"
          log.error msg
          raise ArgumentError.new(msg)
        end
        
        message_pairs = self.class.attr_setters.zip(args).reject {|setter,val| val==nil}
        message_pairs.each {|message| self.send *message}
          
      end
      
      def app
        self.class.app
      end
      
      def schema_class
        self.class.schema_class
      end
      
      def log
        self.class.log
      end
      
      def bang!
        unless schema_class
          log.fatal("No schema class defined for SPQR event class #{self.class.name}; will not raise event.  Did you register this event class?")
          return
        end
        
        log.info("Raising an event of class #{self.class.name}")
        
        event = Qmf::QmfEvent.new(schema_class)
        log.debug "Created QmfEvent is #{event.inspect}"
        
        self.class.spqr_meta.args.each do |arg|
          val = self.send arg.name
          log.debug "setting #{arg.name} of event to #{val}"
          event.send "#{arg.name}=", val
        end
        
        log.debug "event to raise is #{event.inspect} (#{event})"
        log.debug "arguments are #{event.arguments.inspect} (#{event.arguments})"

        
        app.agent.raise_event(event)
      end
    end
        
    def self.included(receiver)
      receiver.extend ClassMixins
      receiver.send :include, InstanceMixins
      
      name_components = receiver.name.to_s.split("::")
      receiver.qmf_class_name name_components.pop
      receiver.qmf_package_name name_components.join(".").downcase
    end
  end
end