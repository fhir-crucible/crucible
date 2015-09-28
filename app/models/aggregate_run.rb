class AggregateRun
  include Mongoid::Document
  field :date, type: DateTime
  belongs_to :server, :class_name => "Server"
  field :results, type: Array

  def serializable_hash(options = nil)
    hash = super(options)
    hash['id'] = hash.delete('_id').to_s if(hash.has_key?('_id'))
    hash
  end

end