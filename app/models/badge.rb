class Badge
	
	include Mongoid::Document
	field :id, type: String
	field :name, type: String
	field :suites, type: Array
	field :tests, type: Array
	field :description, type: String
	field :link, type: String

end