require 'helper'
require 'set'
require 'example-apps'

class TestFailbot < Test::Unit::TestCase
  include QmfTestHelpers

  def setup
    @child_pid = nil
  end

  def test_basic_failure
    app_setup Failbot
    failbot = $console.object(:class=>"Failbot", :agent=>@ag)
    method_response = failbot.fail_with_no_result
    assert_equal 42, method_response.status
    assert_match /This method should not succeed/, method_response.text
  end
end
