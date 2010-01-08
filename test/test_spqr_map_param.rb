require 'helper'
require 'set'
require 'example-apps'

class TestSpqrMapParam < Test::Unit::TestCase
  include QmfTestHelpers

  def setup
    @child_pid = nil
  end

  def test_empty_map
    app_setup QmfMapParam

    obj = nil

    assert_nothing_raised do
      obj = $console.objects(:class=>"QmfMapParam", :agent=>@ag)[0]
    end

    assert_equal({}, obj.dict)
  end

end
