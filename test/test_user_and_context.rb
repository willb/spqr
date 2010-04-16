require 'helper'
require 'set'
require 'example-apps'

class TestUserAndContext < Test::Unit::TestCase
  include QmfTestHelpers

  def setup
    @child_pid = nil
  end

  def test_user_id
    app_setup QmfUserAndContext

    uac = $console.object(:class=>"QmfUserAndContext", :agent=>@ag)
    userid = uac.qmf_user_id.uid
    assert_equal(::ENV['SPQR_TESTS_QMF_USER_ID'] || "anonymous", userid)
  end

  def test_context
    app_setup QmfUserAndContext

    uac = $console.object(:class=>"QmfUserAndContext", :agent=>@ag)
    ctx = uac.qmf_context.ctx

    9.times do 
      old_ctx = ctx
      assert(old_ctx < uac.qmf_context.ctx)
    end
  end
end
