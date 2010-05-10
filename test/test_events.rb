require 'helper'
require 'set'
require 'example-apps'

class TestEvents < Test::Unit::TestCase
  include QmfTestHelpers

  def setup
    @child_pid = nil
    $notify_handler.event_queue.clear if $notify_handler
  end

  def test_dummy_event
    app_setup DummyEvent, QmfDummyEventer
    de = $console.object(:class=>"QmfDummyEventer", :agent=>@ag)
    method_response = de.party_on
    assert_equal 0, method_response.status
    
    sleep 2

    if $QMFENGINE_CONSOLE_SUPPORTS_EVENTS
      ev = Timeout::timeout(5) do
        $notify_handler.event_queue.pop
      end

      # XXX:  make an appropriate assertion about ev here
    end
  end

  def test_arg_event
    app_setup ArgEvent, QmfArgEventer
    de = $console.object(:class=>"QmfArgEventer", :agent=>@ag)
    method_response = de.party_on_one("foobar", 5)
    assert_equal 0, method_response.status
    sleep 2

    if $QMFENGINE_CONSOLE_SUPPORTS_EVENTS
      ev = Timeout::timeout(5) do
        $notify_handler.event_queue.pop
      end

      # XXX:  make an appropriate assertion about ev here
    end
  end
end
