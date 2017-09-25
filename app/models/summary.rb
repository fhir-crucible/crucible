class Summary
  include Mongoid::Document
  belongs_to :test_run
  field :server_id, type: BSON::ObjectId
  field :compliance
  field :generated_at, type: Time
  field :fhir_version, type: String, default: 'stu3'

  index(server_id: 1)
end
