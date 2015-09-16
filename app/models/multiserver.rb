class Multiserver
  include Mongoid::Document
  field :url1, type: String
  field :url2, type: String
  belongs_to :user
end
