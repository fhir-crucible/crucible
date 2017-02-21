class Statistics
  include Mongoid::Document
  field :date, type: DateTime
  field :tests_run, type: Integer

end