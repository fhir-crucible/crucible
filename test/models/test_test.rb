require_relative '../test_helper'

class TestTest < ActiveSupport::TestCase

  def test_serializable_hash
    # check test serializable hash
    assert (JSON.parse(Test.first.to_json).keys & ['_id']).empty?
  end

end