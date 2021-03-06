# SPQR:  Schema Processor for QMF/Ruby agents
#
# Application skeleton class
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

require 'spqr/spqr'
require 'qmf'
require 'logger'

module SPQR
  class App < Qmf::AgentHandler
    VALID_MECHANISMS = %w{ANONYMOUS PLAIN GSSAPI DIGEST-MD5 CRAM-MD5 OTP}

    class ClassMeta < Struct.new(:object_class, :schema_class) ; end

    attr_reader :agent

    def initialize(options=nil)
      defaults = {:logfile=>STDERR, :loglevel=>Logger::WARN, :notifier=>nil, :server=>"localhost", :port=>5672}
      
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
      @qmf_host = options[:server]
      @qmf_port = options[:port]
      @qmf_sendUserId = options.has_key?(:send_user_id) ? options[:send_user_id] : (options.has_key?(:user) || options.has_key?(:password))

      @qmf_explicit_mechanism = options[:mechanism] && options[:mechanism].upcase
      raise "Invalid authentication mechanism #{@qmf_explicit_mechanism}" unless (!@qmf_explicit_mechanism || VALID_MECHANISMS.include?(@qmf_explicit_mechanism))

      @qmf_user = options[:user]
      @qmf_password = options[:password]
    end

    def register(*ks)
      manageable_ks = ks.select {|kl| manageable? kl}
      unmanageable_ks = ks.select {|kl| not manageable? kl}
      manageable_ks.each do |klass|
        @log.info("SPQR will manage registered class #{klass} (#{klass.spqr_meta.classname})...")
        
        schemaclass = schematize(klass)

        klass.log = @log
        
        # XXX
        if klass.included_modules.include?(::SPQR::Manageable)
          @classes_by_id[klass.class_id] = klass        
          @classes_by_name[klass.spqr_meta.classname.to_s] = ClassMeta.new(klass, schemaclass)
        else
          @log.info "NOT registering query/lookup info for #{klass}; is it an event class?"
          @event_classes << klass
        end

        @log.info("SETTING #{klass.spqr_meta.classname}.app to #{self.inspect}")
        klass.app = self        
      end
      
      unmanageable_ks.each do |klass|
        @log.warn("SPQR can't manage #{klass}, which was registered")
      end
    end


    def method_call(context, name, obj_id, args, user_id)
      @log.debug("method_call(#{context.inspect}, #{name.inspect}, #{obj_id.inspect}, #{args.inspect}, #{user_id.inspect})")
      begin
        status = 0
        message = "OK"
        failed = false

        class_id = obj_id.object_num_high
        obj_id = obj_id.object_num_low

        Thread.current[:qmf_user_id] = user_id
        Thread.current[:qmf_context] = context

        managed_object = find_object(context, class_id, obj_id)
        @log.debug("managed object is #{managed_object}")
        managed_method = managed_object.class.spqr_meta.mmethods[name.to_sym]

        raise RuntimeError.new("#{managed_object.class} does not have #{name} exposed as a manageable method; has #{managed_object.class.spqr_meta.mmethods.inspect}") unless managed_method

        # Extract actual parameters from the Qmf::Arguments structure into a proper ruby list
        actuals_in = managed_method.formals_in.inject([]) {|acc,nm| acc << args[nm]}
        actual_count = actuals_in.size
        actuals_out = []

        begin
          actuals_out = case actual_count
            when 0 then managed_object.send(name.to_sym)
            when 1 then managed_object.send(name.to_sym, actuals_in[0])
            else managed_object.send(name.to_sym, *actuals_in)
          end
          
          raise RuntimeError.new("#{managed_object.class} did not return the appropriate number of return values; got '#{actuals_out.inspect}', but expected #{managed_method.types_out.inspect}") unless result_valid(actuals_out, managed_method)
          
        rescue ::SPQR::ManageableObjectError => failure
          @log.warn "#{name} called SPQR::Manageable#fail:  #{failure}"
          status = failure.status
          message = failure.message || "ERROR"
          # XXX:  failure.result is currently ignored
          actuals_out = failure.result || managed_method.formals_out.inject([]) {|acc, val| acc << args[val]; acc}
          failed = true
        end
        
        if managed_method.formals_out.size == 0
          actuals_out = [] # ignore return value in this case
        elsif managed_method.formals_out.size == 1
          actuals_out = [actuals_out] # wrap this up in a list
        end

        unless failed
          # Copy any out parameters from return value to the
          # Qmf::Arguments structure; see XXX above
          managed_method.formals_out.zip(actuals_out).each do |k,v|
            @log.debug("fixing up out params:  #{k.inspect} --> #{v.inspect}")
            encoded_val = encode_object(v)
            args[k] = encoded_val
          end
        end

        @agent.method_response(context, status, message, args)
      rescue Exception => ex
        @log.error "Error calling #{name}: #{ex}"
        @log.error "    " + ex.backtrace.join("\n    ")
        @agent.method_response(context, 1, "ERROR: #{ex}", args)
      end
    end

    def get_query(context, query, user_id)
      @log.debug "get_query: user=#{user_id} context=#{context} class=#{query.class_name} object_num=#{query.object_id && query.object_id.object_num_low} details=#{query}"

      cmeta = @classes_by_name[query.class_name]
      objs = []
      
      # XXX:  are these cases mutually exclusive?
      
      # handle queries for a certain class
      if cmeta
        objs = objs + cmeta.object_class.find_all.collect {|obj| qmfify(obj)}
      end

      # handle queries for a specific object
      o = find_object(context, query.object_id.object_num_high, query.object_id.object_num_low) rescue nil
      if o
        objs << qmfify(o)
      end

      objs.each do |obj| 
        @agent.query_response(context, obj) rescue @log.error($!.inspect)
      end
      
      @log.debug("completing query; returned #{objs.size} objects")
      @agent.query_complete(context)
    end

    def main
      # XXX:  fix and parameterize as necessary
      @log.debug("starting SPQR::App.main...")
      
      settings = Qmf::ConnectionSettings.new
      settings.host = @qmf_host
      settings.port = @qmf_port
      settings.sendUserId = @qmf_sendUserId
      
      settings.username = @qmf_user if @qmf_sendUserId
      settings.password = @qmf_password if @qmf_sendUserId

      implicit_mechanism = @qmf_sendUserId ? "PLAIN" : "ANONYMOUS"
      settings.mechanism = @qmf_explicit_mechanism || implicit_mechanism
      
      @connection = Qmf::Connection.new(settings)
      @log.debug(" +-- @connection created:  #{@connection}")
      @log.debug(" +-- app name is '#{@app_name}'")

      @agent = Qmf::Agent.new(self, @app_name)
      @log.debug(" +-- @agent created:  #{@agent}")
      
      object_class_count = @classes_by_name.size
      event_class_count = @event_classes.size

      @log.info(" +-- registering #{object_class_count} object #{pluralize(object_class_count, "class", "classes")} and #{event_class_count} event #{pluralize(event_class_count, "class", "classes")}....")
      
      all_schemas = @classes_by_name.values + @event_classes
      
      all_schemas.each do |km|
        identifier = ("object #{km.schema_class.package_name}.#{km.schema_class.class_name}" rescue "#{km.class.to_s}")
        
        @log.debug(" +--+-- TRYING to register #{identifier}")
        @agent.register_class(km.schema_class) 
        @log.info(" +--+-- #{identifier} REGISTERED")
      end
      
      @agent.set_connection(@connection)
      @log.debug(" +-- @agent.set_connection called")

      @log.debug("entering orbit....")

      sleep
    end

    private
    
    def pluralize(count, singular, plural=nil)
      plural ||= "#{singular}s"
      count == 1 ? singular : plural
    end
    
    def result_valid(actuals, mm)
      (actuals.kind_of?(Array) and mm.formals_out.size == actuals.size) or mm.formals_out.size <= 1
    end
    
    def qmf_arguments_to_hash(args)
      result = {}
      args.each do |k,v|
        result[k] = v
      end
      result
    end

    def encode_object(o)
      return o unless o.kind_of? ::SPQR::Manageable
      @agent.alloc_object_id(*(o.qmf_id))
    end

    def find_object(ctx, c_id, obj_id)
      # XXX:  context is currently ignored
      klass = @classes_by_id[c_id]
      klass.find_by_id(obj_id) if klass
    end
    
    def schematize(klass)
      @log.info("Making a QMF schema for #{klass.spqr_meta.classname}")

      if klass.respond_to? :schematize
        @log.info("#{klass.spqr_meta.classname} knows how to schematize itself; it's probably an event class")
        return klass.schematize 
      else
        @log.info("#{klass.spqr_meta.classname} doesn't know how to schematize itself; it's probably an object class")
        return schematize_object_class(klass)
      end
    end
    
    def schematize_object_class(klass)
      meta = klass.spqr_meta
      package = meta.package.to_s
      classname = meta.classname.to_s
      @log.info("+-- class #{classname} is in package #{package}")

      sc = Qmf::SchemaObjectClass.new(package, classname)
      
      meta.manageable_methods.each do |mm|
        @log.info("+-- creating a QMF schema for method #{mm}")
        m_opts = mm.options
        m_opts[:desc] ||= mm.description if mm.description
        
        method = Qmf::SchemaMethod.new(mm.name.to_s, m_opts)
        
        mm.args.each do |arg| 
          @log.info("| +-- creating a QMF schema for arg #{arg}")
          
          encode_argument(arg, method)
        end

        sc.add_method(method)
      end

      add_attributes(sc, meta.properties, :add_property, Qmf::SchemaProperty)
      add_attributes(sc, meta.statistics, :add_statistic, Qmf::SchemaStatistic)

      sc
    end
    
    def add_attributes(sc, collection, msg, klass, what=nil)
      what ||= (msg.to_s.split("_").pop rescue "property or statistic")
      collection.each do |basic|
        basic_name = basic.name.to_s
        basic_type = get_xml_constant(basic.kind.to_s, ::SPQR::XmlConstants::Type)
        basic.options[:access] = get_xml_constant(basic.options[:access].to_s.upcase, ::SPQR::XmlConstants::Access) if basic.options[:access]
        @log.debug("+-- creating a QMF schema for #{what} #{basic_name} (#{basic_type}) with options #{basic.options.inspect}")
        sc.send(msg, klass.new(basic_name, basic_type, basic.options))
      end
    end

    include ::SPQR::Util
    
    # turns an instance of a managed object into a QmfObject
    def qmfify(obj)
      @log.debug("qmfify: treating instance of #{obj.class.name}:  qmf_oid is #{obj.qmf_oid} and class_id is #{obj.class.class_id}")
      cm = @classes_by_name[obj.class.spqr_meta.classname.to_s]
      return nil unless cm

      qmfobj = Qmf::AgentObject.new(cm.schema_class)

      set_attrs(qmfobj, obj)

      oid = @agent.alloc_object_id(obj.qmf_oid, obj.class.class_id)
      qmfobj.set_object_id(oid)
      qmfobj
    end

    def set_attrs(qo, o)
      return unless o.class.respond_to? :spqr_meta
      
      attrs = o.class.spqr_meta.properties + o.class.spqr_meta.statistics

      attrs.each do |a|
        getter = a.name.to_s
        value = o.send(getter) if o.respond_to?(getter)

        if value || a.kind == :bool
          # XXX: remove this line when/if Manageable includes an
          # appropriate impl method
          value = encode_object(value) if value.kind_of?(::SPQR::Manageable)
          qo[getter] = value
        end

      end
    end
  end
end
