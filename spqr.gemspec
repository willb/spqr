# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{spqr}
  s.version = "0.3.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["William Benton"]
  s.date = %q{2011-11-23}
  s.default_executable = %q{spqr-gen.rb}
  s.description = %q{SPQR makes it very simple to expose methods on Ruby objects over QMF.  You must install ruby-qmf in order to use SPQR.}
  s.email = %q{willb@redhat.com}
  s.executables = ["spqr-gen.rb"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc",
    "TODO"
  ]
  s.files = [
    ".document",
    "CHANGES",
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "TODO",
    "VERSION",
    "bin/spqr-gen.rb",
    "examples/codegen-schema.xml",
    "examples/hello.rb",
    "examples/logdaemon.rb",
    "examples/logservice.rb",
    "lib/spqr/app.rb",
    "lib/spqr/codegen.rb",
    "lib/spqr/constants.rb",
    "lib/spqr/event.rb",
    "lib/spqr/manageable.rb",
    "lib/spqr/spqr.rb",
    "lib/spqr/utils.rb",
    "ruby-spqr.spec.in",
    "spec/spec.opts",
    "spec/spec_helper.rb",
    "spec/spqr_spec.rb",
    "spqr.spec.in",
    "test/example-apps.rb",
    "test/generic-agent.rb",
    "test/helper.rb",
    "test/test_events.rb",
    "test/test_failbot.rb",
    "test/test_spqr_boolprop.rb",
    "test/test_spqr_clicker.rb",
    "test/test_spqr_dummyprop.rb",
    "test/test_spqr_hello.rb",
    "test/test_spqr_integerprop.rb",
    "test/test_spqr_listarg.rb",
    "test/test_user_and_context.rb"
  ]
  s.homepage = %q{http://git.fedorahosted.org/git/grid/spqr.git}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{SPQR:  {Schema Processor|Straightforward Publishing} for QMF agents in Ruby}
  s.test_files = [
    "examples/hello.rb",
    "examples/logdaemon.rb",
    "examples/logservice.rb",
    "spec/spec_helper.rb",
    "spec/spqr_spec.rb",
    "test/example-apps.rb",
    "test/generic-agent.rb",
    "test/helper.rb",
    "test/test_events.rb",
    "test/test_failbot.rb",
    "test/test_spqr_boolprop.rb",
    "test/test_spqr_clicker.rb",
    "test/test_spqr_dummyprop.rb",
    "test/test_spqr_hello.rb",
    "test/test_spqr_integerprop.rb",
    "test/test_spqr_listarg.rb",
    "test/test_user_and_context.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 1.2.9"])
    else
      s.add_dependency(%q<rspec>, [">= 1.2.9"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 1.2.9"])
  end
end

