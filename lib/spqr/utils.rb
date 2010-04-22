# Utility functions and modules for SPQR
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
  class Sink
    def method_missing(*args)
      yield if block_given?
      nil
    end
  end

  module PrettyPrinter
    def writemode
      $PP_WRITEMODE ||= File::WRONLY|File::CREAT|File::TRUNC
    end

    def stack
      @fstack ||= [STDOUT]
    end

    def inc_indent
      @indent = indent + 2
    end

    def dec_indent
      @indent = indent - 2
    end

    def indent
      @indent ||= 0
    end

    def outfile
      @fstack[-1] or STDOUT
    end

    def pp(s)
      outfile.puts "#{' ' * indent}#{s}\n"
    end

    def pp_decl(kind, name, etc=nil)
      pp "#{kind} #{name}#{etc}"
      inc_indent
      yield if block_given?
      dec_indent
      pp "end"
    end

    def pp_call(callable, args)
      arg_repr = args.map {|arg| (arg.inspect if arg.kind_of? Hash) or arg}.join(', ')
      pp "#{callable}(#{arg_repr})"
    end

    def pp_invoke(receiver, method, args)
      pp_call "#{receiver}.#{method}", args
    end

    def with_output_to(filename, &action)
      File::open(filename, writemode) do |of|
        stack << of
        action.call      
        stack.pop
      end
    end
  end
  
  module Util
    def symbolize_dict(k, kz=nil)
      k2 = {}
      kz ||= k.keys

      k.keys.each do |key|
        k2[key.to_sym] = k[key] if (kz.include?(key) || kz.include?(key.to_sym))
      end

      k2
    end
    
    def get_xml_constant(xml_key, dictionary)
      string_val = dictionary[xml_key]
      return xml_key unless string_val

      actual_val = const_lookup(string_val)
      return string_val unless actual_val

      return actual_val
    end
    
    # turns a string name of a constant into the value of that
    # constant; returns that value, or nil if fqcn doesn't correspond
    # to a valid constant
    def const_lookup(fqcn)
      # FIXME:  move out of App, into a utils module?
      hierarchy = fqcn.split("::")
      const = hierarchy.pop
      mod = Kernel
      hierarchy.each do |m|
        mod = mod.const_get(m)
      end
      mod.const_get(const) rescue nil
    end
    
    def encode_argument(arg, destination)
      arg_opts = arg.options
      arg_opts[:desc] ||= arg.description if (arg.description && arg.description.is_a?(String))
      arg_opts[:dir] ||= get_xml_constant(arg.direction.to_s, ::SPQR::XmlConstants::Direction) if arg.respond_to? :direction
      arg_name = arg.name.to_s
      arg_type = get_xml_constant(arg.kind.to_s, ::SPQR::XmlConstants::Type)

      destination.add_argument(Qmf::SchemaArgument.new(arg_name, arg_type, arg_opts))
    end
    
    def manageable?(k)
      k.is_a?(Class) && (k.included_modules.include?(::SPQR::Manageable) || k.included_modules.include?(::SPQR::Raiseable))
    end
    
  end
end
