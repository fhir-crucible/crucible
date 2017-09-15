class SmartClient
  include Mongoid::Document
  field :name, type: String
  field :client_id, type: String
  field :scopes, type: String

end
