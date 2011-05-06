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
require 'logger'

module SPQR
  BACKENDS = %w{qmf http}
  DEFAULT_BACKEND = ENV['SPQR_DEFAULT_BACKEND'] || $SPQR_DEFAULT_BACKEND || 'qmf'
  DEFAULT_OPTIONS = {:backend=>DEFAULT_BACKEND}
  APPCLASS = "App"

  def self.setup(options = nil)
    options ||= DEFAULT_OPTIONS.dup.merge(options || {})
    backend = options[:backend]
    unless BACKENDS.include?(backend)
      raise RuntimeError.new("unknown SPQR backend #{backend.inspect}")
    end
    
    require "spqr/#{backend}_app"
    backend_class = self.const_get("#{backend.capitalize}#{APPCLASS}")
    const_remove(APPCLASS) if self.const_defined?(APPCLASS)
    self.const_set(APPCLASS, backend_class)
  end
  
  setup
end
