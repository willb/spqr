require 'helper'
require 'set'
require 'example-apps'

class TestListArg < Test::Unit::TestCase
  include QmfTestHelpers

  def setup
    @child_pid = nil
  end

  def test_property_identities
    app_setup QmfListArg

    somenats = (0..16).to_a

    obj = $console.object(:class=>"QmfListArg")

    ls = obj.double(somenats).ls
    
    assert_equal ls.size, somenats.size
    somenats.zip(ls).each {|n,n2| assert_equal(n*2, n2) }
  end
end
