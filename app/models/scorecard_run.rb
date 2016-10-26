class ScorecardRun
  include Mongoid::Document
  field :url, type: String
  field :date, type: DateTime
  field :result
end
