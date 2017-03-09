class Statistics
  include Mongoid::Document
  field :date, type: DateTime, default: ->{ DateTime.now }
  field :tests_run, type: Integer, default: 0

end
