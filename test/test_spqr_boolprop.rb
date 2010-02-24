require 'helper'
require 'set'
require 'example-apps'

class TestBoolProp < Test::Unit::TestCase
  include QmfTestHelpers

  def setup
    @child_pid = nil
  end

  def test_property_identities
    app_setup QmfBoolProp

    objs = $console.objects(:class=>"QmfBoolProp")
    ids = Set.new

    assert_equal QmfBoolProp::SIZE, objs.size

    objs.each do |obj|
      assert_equal((obj.int_id % 2 == 0), obj.is_id_even)
      ids << obj[:int_id]
    end

    assert_equal objs.size, ids.size
    
    objs.size.times do |x|
      assert ids.include?(x), "ids should include #{x}, which is less than #{objs.size}"
    end
  end
end
