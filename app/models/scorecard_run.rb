class ScorecardRun
  include Mongoid::Document
  field :url, type: String
  field :date, type: DateTime
  field :result

  # only uses the first result in the array if any
  def get_score
    if result.length == 0
      return -1
    else
      return result[0][:points]
    end
  end
  
end
