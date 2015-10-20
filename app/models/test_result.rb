class TestResult
  include Mongoid::Document
  include Mongoid::Timestamps
  belongs_to :test
  belongs_to :test_run
  belongs_to :server
  field :has_run, type: Boolean, default: false
  field :result

end
