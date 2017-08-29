class Test
  include Mongoid::Document
  field :id, type: String
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
  field :supported, type: Boolean, default: false
  field :load_version, type: Integer, default: 0
  field :tags, type: Array
  field :details, type: Hash
  field :category, type: Hash
  field :supported_versions, type: Array, default: [] # stu3, dstu2, etc

  def serializable_hash(options = nil)
    hash = super(options)
    hash['id'] = hash.delete('_id').to_s if(hash.has_key?('_id'))
    hash
  end

end
