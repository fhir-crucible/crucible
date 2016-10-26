class SyntheaRun
  include Mongoid::Document
  field :url, type: String
  field :format, type: String
  field :count, type: Integer
  field :date, type: DateTime
end
