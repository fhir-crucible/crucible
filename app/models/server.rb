class Server
  attr_accessor :raw_conformance

  include Mongoid::Document
  field :name, type: String
  field :url, type: String
  belongs_to :summary
  has_one :aggregate_run
  field :percent_passing, type: Float
  field :conformance

  def load_conformance
    @raw_conformance ||= FHIR::Client.new(self.url).conformanceStatement
    conformance = JSON.parse(@raw_conformance.to_json(except: :_id))
    conformance['rest'].each do |rest|
      rest['operation'] = rest['operation'].reduce({}) {|memo,operation| memo[operation['name']]=true; memo}
      rest['resource'].each do |resource|
        resource['operation'] = resource['interaction'].reduce({}) {|memo,operation| memo[operation['code']]=true; memo}
      end
    end
    conformance
  end
end
