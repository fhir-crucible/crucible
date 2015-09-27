class Summary
  include Mongoid::Document
  belongs_to :test_run
  field :server_id, type: Moped::BSON::ObjectId
  field :compliance
  field :generated_at, type: Time
end
