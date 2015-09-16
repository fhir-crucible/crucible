class Summary
  include Mongoid::Document
  belongs_to :server
  belongs_to :test_run
  field :compliance
  field :generated_at, type: Time
end
