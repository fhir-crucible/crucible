class Scope
  include Mongoid::Document
  field :name, type: String
  field :description, type: String
  field :selected, type: Boolean, default: false
  field :elem_id, type: String
  embedded_in :server
end
