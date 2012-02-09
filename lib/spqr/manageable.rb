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
  class ManageableObjectError < RuntimeError
    attr_accessor :status, :result

    def initialize(status, message=nil, rval=nil)
      super(message)
      @status = status
      @result = rval
    end
  end
  
  class ManageableMeta < Struct.new(:classname, :package, :description, :mmethods, :options, :statistics, :properties)
    def initialize(*a)
      super *a
      self.options = (({} unless self.options) or self.options.dup)
      self.statistics = [] unless self.statistics
      self.properties = [] unless self.properties
      self.mmethods ||= {}
    end

    def declare_method(name, desc, options, blk=nil)
      result = MethodMeta.new name, desc, options
      blk.call(result.args) if blk
      self.mmethods[name] = result
    end

    def manageable_methods
      self.mmethods.values
    end
    
    def declare_statistic(name, kind, options)
      declare_basic(:statistic, name, kind, options)
    end

    def declare_property(name, kind, options)
      declare_basic(:property, name, kind, options)
    end

    private
    def declare_basic(what, name, kind, options)
      what_plural = "#{what.to_s.gsub(/y$/, 'ie')}s"
      w_get = what_plural.to_sym
      w_set = "#{what_plural}=".to_sym

      self.send(w_set, (self.send(w_get) or []))

      w_class = "#{what.to_s.capitalize}Meta"
      self.send(w_get) << SPQR.const_get(w_class).new(name, kind, options)
    end
  end

  class MethodMeta < Struct.new(:name, :description, :args, :options)
    def initialize(*a)
      super *a
      self.options = (({} unless self.options) or self.options.dup)
      self.args = gen_args
    end

    def formals_in
      self.args.select {|arg| arg.direction == :in or arg.direction == :inout}.collect{|arg| arg.name.to_s}
    end

    def formals_out
      self.args.select {|arg| arg.direction == :inout or arg.direction == :out}.collect{|arg| arg.name.to_s}
    end

    def types_in
      self.args.select {|arg| arg.direction == :in or arg.direction == :inout}.collect{|arg| arg.kind.to_s}
    end
    
    def types_out
      self.args.select {|arg| arg.direction == :inout or arg.direction == :out}.collect{|arg| arg.kind.to_s}
    end

    def type_of(param)
      @types_for ||= self.args.inject({}) do |acc,arg| 
        k = arg.name
        v = arg.kind.to_s
        acc[k] = v
        acc[k.to_s] = v
        acc
      end
      
      @types_for[param]
    end

    private
    def gen_args
      result = []

      def result.declare(name, kind, direction, description=nil, options=nil)
        options ||= {}
        arg = ::SPQR::ArgMeta.new name, kind, direction, description, options.dup
        self << arg
      end

      result
    end
  end

  class ArgMeta < Struct.new(:name, :kind, :direction, :description, :options)
    def initialize(*a)
      super *a
      self.options = (({} unless self.options) or self.options.dup)
    end
  end

  class PropertyMeta < Struct.new(:name, :kind, :options)
    def initialize(*a)
      super *a
      self.options = (({} unless self.options) or self.options.dup)
    end
  end

  class StatisticMeta < Struct.new(:name, :kind, :options)
    def initialize(*a)
      super *a
      self.options = (({} unless self.options) or self.options.dup)
    end
  end

  module ManageableClassMixins
    def spqr_meta
      @spqr_meta ||= ::SPQR::ManageableMeta.new
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
    
    # Exposes a method to QMF
    def expose(name, description=nil, options=nil, &blk)
      spqr_meta.declare_method(name, description, options, blk)
    end

    # Declares that this class is a singleton class; that is, only one
    # instance will be published over QMF
    def is_singleton
      def self.instances
        @instances ||= [self.new]
      end

      def self.find_all
        instances
      end

      def self.find_by_id(id)
        instances[0]
      end
    end

    # Declares that instances of this class will automatically be
    # tracked (and find_all and find_by_id methods generated).
    # Instances of automatically-tracked classes must be explicitly
    # deleted (with the delete class method).  Do not use automatic
    # tracking with Rhubarb, which automatically tracks instances for
    # you.
    def is_tracked
      # no pun intended, I promise
      alias_method :old_new, :new
      
      def self.instances
        @instances ||= {}
      end

      def self.find_all
        instances.values
      end

      def self.find_by_id(id)
        instances[id]
      end
      
      # XXX:  would it make more sense to call allocate and initialize explicitly?
      def self.new(*args)
        result = old_new(*args)
        instances[result.qmf_oid] = result
        result
      end

      def self.delete(instance)
        instances.delete(instance.qmf_oid)
      end
    end

    def qmf_package_name(nm)
      spqr_meta.package = nm
    end
    
    def qmf_class_name(nm)
      spqr_meta.classname = nm
    end
    
    def qmf_description(d)
      spqr_meta.description = d
    end
    
    def qmf_options(opts)
      spqr_meta.options = opts.dup
    end      
    
    def qmf_statistic(name, kind, options=nil)
      spqr_meta.declare_statistic(name, kind, options)
      
      self.class_eval do
        # XXX: are we only interested in declaring a reader for
        # statistics?  Doesn't it really makes more sense for the managed
        # class to declare a method with the same name as the
        # statistic so we aren't declaring anything at all here?
        
        # XXX: should cons up a "safe_attr_reader" method that works
        # like this:
        attr_reader name.to_sym unless method_defined? "#{name}"
        attr_writer name.to_sym unless method_defined? "#{name}="
      end
    end
    
    def qmf_property(name, kind, options=nil)
      spqr_meta.declare_property(name, kind, options)
      
      # add a property accessor to instances of other
      self.class_eval do
        # XXX: should cons up a "safe_attr_accessor" method that works like this:
        attr_reader name.to_sym unless method_defined? "#{name}"
        attr_writer name.to_sym unless method_defined? "#{name}="
      end
      
      if options and options[:index]
        # if this is an index property, add a find-by method if one
        # does not already exist
        spqr_define_index_find(name)
      end
    end
    
    private
    def spqr_define_index_find(name)
      find_by_prop = "find_by_#{name}".to_sym

      return if self.respond_to? find_by_prop

      define_method find_by_prop do |arg|
        raise "#{self} must define find_by_#{name}(arg)"
      end
    end
  end

  module Manageable
    # fail takes either (up to) three arguments or a hash
    # the three arguments are:
    #   * =status= (an integer failure code)
    #   * =message= (a descriptive failure message, defaults to nil)
    #   * =result= (a value to return, defaults to nil; currently ignored by QMF)
    # the hash simply maps from keys =:status=, =:message=, and =:result= to their respective values.  Only =:status= is required.
    def fail(*args)
      unless args.size <= 3 && args.size >= 1
        raise RuntimeError.new("SPQR::Manageable#fail takes at least one parameter but not more than three; received #{args.inspect}")
      end
      
      if args.size == 1 and args[0].class = Hash
        failhash = args[0]
        
        unless failhash[:status] && failhash[:status].is_a?(Fixnum)
          raise RuntimeError.new("SPQR::Manageable#fail requires a Fixnum-valued :status parameter when called with keyword arguments; received #{failhash[:status].inspect}")
        end
        
        raise ManageableObjectError.new(failhash[:status], failhash[:message], failhash[:result])
      end
      
      raise ManageableObjectError.new(*args)
    end
    
    # Returns the user ID of the QMF user invoking this method
    def qmf_user_id
      Thread.current[:qmf_user_id]
    end

    # Returns QMF context of the current method invocation
    def qmf_context
      Thread.current[:qmf_context]
    end

    def qmf_oid
      result = 0
      if self.respond_to? :spqr_object_id 
        result = spqr_object_id
      elsif self.respond_to? :row_id
        result = row_id
      else
        result = object_id
      end
      
      # XXX:  this foolishly assumes that we are running on a 64-bit machine or a 32-bit machine
      result & (0.size == 8 ? 0x7fffffff : 0x3fffffff)
    end

    def qmf_id
      [qmf_oid, self.class.class_id]
    end

    def log
      self.class.log
    end

    def self.included(other)
      class << other
        include ManageableClassMixins
        alias_method :qmf_singleton, :is_singleton
      end

      unless other.respond_to? :find_by_id
        def other.find_by_id(id)
          raise "#{self} must define find_by_id(id)"
        end
      end

      unless other.respond_to? :find_all
        def other.find_all
          raise "#{self} must define find_all"
        end
      end

      unless other.respond_to? :class_id
        def other.class_id
          package_list = spqr_meta.package.to_s.split(".")
          cls = spqr_meta.classname.to_s or self.name.to_s
          
          # XXX:  this foolishly assumes that we are running on a 64-bit machine or a 32-bit machine
          ((package_list.map {|pkg| pkg.capitalize} << cls).join("::")).hash & (0.size == 8 ? 0x7fffffff : 0x3fffffff)
        end
      end

      name_components = other.name.to_s.split("::")
      other.qmf_class_name name_components.pop
      other.qmf_package_name name_components.join(".").downcase
    end
  end
end
