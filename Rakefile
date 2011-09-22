require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "spqr"
    gem.summary = %Q{SPQR:  {Schema Processor|Straightforward Publishing} for QMF agents in Ruby}
    gem.description = %Q{SPQR makes it very simple to expose methods on Ruby objects over QMF.  You must install ruby-qmf in order to use SPQR.}
    gem.email = "willb@redhat.com"
    gem.homepage = "http://git.fedorahosted.org/git/grid/spqr.git"
    gem.authors = ["William Benton"]
    gem.add_development_dependency "rspec", ">= 1.2.9"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

def pkg_version
  version = File.exist?('VERSION') ? File.read('VERSION') : ""
  return version.chomp
end

def name
  return "spqr"
end

def pkg_name
  return "ruby-" + name()
end

def pkg_spec
  return pkg_name() + ".spec"
end

def pkg_rel
  return `grep -i 'define rel' #{pkg_spec} | awk '{print $3}'`.chomp()
end

def pkg_source
  return "#{pkg_name}-#{pkg_version}.tar.gz"
end

def pkg_dir
  return pkg_name() + "-" + pkg_version()
end

def rpm_dirs
  return %w{BUILD BUILDROOT RPMS SOURCES SPECS SRPMS}
end

desc "create an RPM spec file"
task :rpmspec => :build do
  sh "gem2rpm -t spqr.spec.in -o spqr.spec pkg/spqr-#{pkg_version}.gem"
end

desc "create RPMs"
task :rpms => [:build, :tarball, :gen_spec] do
  FileUtils.cp pkg_spec(), 'SPECS'
  sh "rpmbuild --define=\"_topdir \${PWD}\" -ba SPECS/#{pkg_spec}"
end

desc "Generate the specfile"
task :gen_spec do
  sh "cat #{pkg_spec}" + ".in" + "| sed 's/SPQR_VERSION/#{pkg_version}/' > #{pkg_spec}"
end

desc "Create a tarball"
task :tarball => [:make_rpmdirs, :gen_spec] do
  FileUtils.cp_r 'bin', pkg_dir()
  FileUtils.cp_r 'lib', pkg_dir()
  FileUtils.cp_r 'examples', pkg_dir()
  FileUtils.cp ['LICENSE', 'README.rdoc', 'CHANGES', 'TODO', 'VERSION'], pkg_dir()
  sh "tar -cf #{pkg_source} #{pkg_dir}"
  FileUtils.mv pkg_source(), 'SOURCES'
end

desc "Make dirs for building RPM"
task :make_rpmdirs => :clean do
  FileUtils.mkdir pkg_dir()
  FileUtils.mkdir rpm_dirs()
end

desc "Cleanup after an RPM build"
task :clean do
  require 'fileutils'
  FileUtils.rm_r [pkg_dir(), rpm_dirs(), pkg_spec(), 'pkg', name() + ".gemspec"], :force => true
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies


require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

begin
  require 'reek/adapters/rake_task'
  Reek::RakeTask.new do |t|
    t.fail_on_error = true
    t.verbose = false
    t.source_files = 'lib/**/*.rb'
  end
rescue LoadError
  task :reek do
    abort "Reek is not available. In order to run reek, you must: sudo gem install reek"
  end
end

begin
  require 'roodi'
  require 'roodi_task'
  RoodiTask.new do |t|
    t.verbose = false
  end
rescue LoadError
  task :roodi do
    abort "Roodi is not available. In order to run roodi, you must: sudo gem install roodi"
  end
end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "spqr #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
