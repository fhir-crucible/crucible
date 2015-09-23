class Test
  include Mongoid::Document
  field :name
  field :title
  field :resource_class, type: String, default: ''
  field :author
  field :description
  field :validates
  field :requires
  field :links
  field :multiserver, type: Boolean, default: false
  field :methods, type: Array

  def serializable_hash(options = nil)
    hash = super(options)
    hash['id'] = hash.delete('_id').to_s if(hash.has_key?('_id'))
    hash
  end

end
