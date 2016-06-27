class Dashboard
  include Mongoid::Document

  field :title, type: String
  field :description, type: String
  field :tag, type: String
end
