class Summary
  include Mongoid::Document
  belongs_to :test_run
  field :server_id, type: BSON::ObjectId
  field :compliance
  field :generated_at, type: Time

  index(server_id: 1)
end
