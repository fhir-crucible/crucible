class SmartClient
  include Mongoid::Document
  field :name, type: String
  field :id, type: String
  field :scopes, type: String

end
