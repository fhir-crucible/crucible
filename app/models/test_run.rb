class TestRun
  include Mongoid::Document
  field :conformance
  field :destination_conformance
  field :date, type: DateTime
  field :is_multiserver, type: Boolean, default: false
  belongs_to :server, :class_name => "Server"
  belongs_to :destination_server, :class_name => "Server"
  belongs_to :user
  field :nightly, type: Boolean, default: false
  has_many :test_results, autosave: true
end
