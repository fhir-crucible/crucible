class SmartRun
  include Mongoid::Document
  field :report
  field :time_diff
  belongs_to :smart_client

end
