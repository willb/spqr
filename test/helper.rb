require 'rubygems' rescue nil
require 'test/unit'
require 'qmf'
require 'timeout'
require 'thread'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'spqr/spqr'
require 'spqr/app'

module QmfTestHelpers
  DEBUG = (::ENV["SPQR_TESTS_DEBUG"] && ((::ENV["SPQR_TESTS_DEBUG"].downcase == "yes" && "yes") || (::ENV["SPQR_TESTS_DEBUG"].downcase == "trace" && "trace")))
  
  class AgentNotifyHandler < Qmf::ConsoleHandler
    def initialize
      @q = Queue.new
    end
    
    def queue
      @q
    end

    def agent_added(agent)
      puts "GOT AN AGENT:  #{agent} at #{Time.now.utc}" if DEBUG
      @q << agent
    end
  end

  def app_setup(*classes)
    unless $broker
      $notify_handler = AgentNotifyHandler.new
      $connection = Qmf::Connection.new(Qmf::ConnectionSettings.new)
      $console = Qmf::Console.new($notify_handler)
      $broker = $console.add_connection($connection)
    end
    
    sleep 0.5
    $broker.wait_for_stable
        
    @child_pid = fork do 
      sleep 0.5
      unless DEBUG
        # replace stdin/stdout/stderr
        $stdin.reopen("/dev/null", "r")
        $stdout.reopen("/dev/null", "w")
        $stderr.reopen("/dev/null", "w")
      else
        ENV['QPID_TRACE'] = "1" if DEBUG == "trace"
      end

      exec("#{File.dirname(__FILE__)}/generic-agent.rb", *classes.map {|cl| cl.to_s})
      exit! 127

      @app = SPQR::App.new(:loglevel => (DEBUG ? :debug : :fatal), :appname=>"#{classes.join("")}[#{Process.pid}]")
      @app.register *classes

      @app.main
    end
    
    begin
      Timeout.timeout(12) do
        k = ""
        begin
          @ag = $notify_handler.queue.pop
          k = @ag.key
          puts "GOT A KEY:  #{k} at #{Time.now.utc}" if DEBUG
        end until k != "1.0"

        # XXX
        puts "ESCAPING FROM TIMEOUT at #{Time.now.utc}" if DEBUG
      end
    rescue Timeout::Error
      puts "QUEUE SIZE WAS #{$notify_handler.queue.size} at #{Time.now.utc}" if DEBUG
      raise
    end

  end

  def teardown
    Process.kill(9, @child_pid) if @child_pid
  end
end

class Test::Unit::TestCase
end
