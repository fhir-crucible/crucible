class Server
  attr_accessor :raw_conformance

  include Mongoid::Document
  field :name, type: String
  field :url, type: String
  belongs_to :summary
  has_one :aggregate_run
  field :percent_passing, type: Float
  field :conformance, type: String
  field :state, type: String
  field :oauth_code, type: String
  field :client_id, type: String
  field :client_secret, type: String
  field :authorize_url, type: String
  field :token_url, type: String
  field :oauth_token_opts, type: Hash

  def load_conformance(refresh=false)
    if (self.conformance.nil? || refresh)
      @raw_conformance ||= FHIR::Client.new(self.url).conformanceStatement
      self.conformance = @raw_conformance.to_json(except: :_id)
      self.save!
    end
    value = JSON.parse(self.conformance)

    value['rest'].each do |rest|
      rest['operation'] = rest['operation'].reduce({}) {|memo,operation| memo[operation['name']]=true; memo}
      rest['resource'].each do |resource|
        resource['operation'] = resource['interaction'].reduce({}) {|memo,operation| memo[operation['code']]=true; memo}
      end
    end
    value
  end

  def generate_state
    SecureRandom.urlsafe_base64(24)
  end

  def get_oauth2_client
    options = {
      authorize_url: self.authorize_url,
      token_url: self.token_url,
      raise_errors: false
    }
    client = OAuth2::Client.new(self.client_id, self.client_secret, options)
    token = OAuth2::AccessToken.from_hash(client, self.oauth_token_opts)
    return token
  end

end
