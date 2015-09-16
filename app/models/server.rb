class Server
  attr_accessor :raw_conformance

  include Mongoid::Document
  field :name, type: String
  field :url, type: String

  def load_conformance
    @raw_conformance ||= FHIR::Client.new(self.url).conformanceStatement
    conformance = JSON.parse(@raw_conformance.to_json)
    conformance['rest'].each do |rest|
      rest['operation'] = rest['operation'].reduce({}) {|memo,operation| memo[operation['name']]=true; memo}
      rest['resource'].each do |resource|
        resource['operation'] = resource['interaction'].reduce({}) {|memo,operation| memo[operation['code']]=true; memo}
      end
    end
    conformance
  end
end
