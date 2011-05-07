# SPQR:  Schema Processor for QMF/Ruby agents
#
# HTTP/JSON-RPC application skeleton class.  Maybe best described as
# "RES", since it's about 75% RESTful.
#
# Copyright (c) 2009--2011 Red Hat, Inc.
#
# Author:  William Benton (willb@redhat.com)
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0

module SPQR
  class HttpApp
    def initialize(options=nil)
            defaults = {:logfile=>STDERR, :loglevel=>Logger::WARN, :notifier=>nil, :port=>9529}
      
      # convenient shorthands for log levels
      loglevels = {:debug => Logger::DEBUG, :info => Logger::INFO, :warn => Logger::WARN, :error => Logger::ERROR, :fatal => Logger::FATAL}
        
      options = defaults unless options

      # set unsupplied options to defaults
      defaults.each do |k,v|
        options[k] = v unless options[k]
      end

      # fix up shorthands
      options[:loglevel] = loglevels[options[:loglevel]] if loglevels[options[:loglevel]]

      logger_opts = ([options[:logfile]] + [options[:logoptions]]).flatten.compact

      @log = Logger.new(*logger_opts)
      @log.level = options[:loglevel]

      @log.info("initializing SPQR app....")

      @event_classes = []
      @classes_by_name = {}
      @classes_by_id = {}
      @pipe = options[:notifier]
      @app_name = (options[:appname] or "SPQR application [#{Process.pid}]")
      
    end

    def register(*ks)
      manageable_ks = ks.select {|kl| manageable? kl}
      unmanageable_ks = ks.select {|kl| not manageable? kl}

      manageable_ks.each do |klass|
        
      end
    end

    private
    def camel2url(klass)
      klass.to_s.split('::').pop.gsub(/([A-Z])([A-Z])([a-z])/, '\1_\2\3').gsub(/([a-z])([A-Z])/, '\1_\2').downcase
    end
  end
end
