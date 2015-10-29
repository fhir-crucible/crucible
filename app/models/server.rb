class Server
  require 'json'

  attr_accessor :raw_conformance

  include Mongoid::Document
  field :name, type: String
  field :url, type: String
  belongs_to :summary
  has_one :aggregate_run
  field :percent_passing, type: Float
  field :conformance, type: String
  field :state, type: String
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

  def get_compliance()
    #todo: investigate moving this elsewhere.
    compliance_file = File.join(Rails.root, 'lib', 'compliance.json')
    compliance = JSON.parse(File.read(compliance_file))

    node_map = {}
    build_compliance_node_map(compliance, node_map)
    self.aggregate_run.results.each do |result|
      result['validates'].each do |validation|
        if validation[:resource]
          update_node(node_map, validation[:resource].titleize.downcase, result)
        end
        if validation[:methods]
          validation[:methods].each do |method|
            update_node(node_map, method, result)
          end
        end
        if validation[:formats]
          validation[:formats].each do |format|
            update_node(node_map, format, result)
          end
        end
        if validation[:extensions]
          validation[:extensions].each do |extension|
            update_node(node_map, extension, result)
          end
        end
        if validation[:profiles]
          validation[:profiles].each do |profile|
            update_node(node_map, profile, result)
          end
        end

      end if result['validates']
    end

    rollup(compliance)

    compliance
  end

  def aggregate(test_run)
    self.aggregate_run ||= AggregateRun.new
    aggregate_run = self.aggregate_run
    aggregate_run.results ||= []
    
    result_map = {}
    test_run.test_results.each do |test_result|
      test_result.result.each do |result|
        id = result['id']
        if result_map[id]
          puts "\tduplicate id: #{id}!!!!!!!" 
        else
          result['test_result_id'] = test_result.id
          result['test_id'] = test_result.test_id
          result_map[id] = result.except('code')
        end
      end
    end

    latest_results = aggregate_run.results.map {|result| (result_map.delete(result['id']) || result.except('code')) }
    latest_results.concat(result_map.values)
    aggregate_run.results = latest_results
    aggregate_run.date = Time.now
    aggregate_run.save!
    self.save!
  end

  def available?
    begin
      x = (RestClient::Request.execute(:method => :get, :url => self.url+'/metadata', :timeout => 30, :open_timeout => 30)).match /Conformance/
      unless x
        puts "Server Not Available"
        return false
      end
    rescue
      puts "Server not available"
      return false
    end
    
    true
  end


  private

  def rollup(node)
    if node['children']
      node['children'].each do |child|
        rollup(child)
      end
      ['passed', 'failed', 'errors', 'skipped'].each do |key|
        node["#{key}Ids"].concat(node['children'].map {|n| n["#{key}Ids"]}.flatten.uniq)
        node["#{key}Ids"].uniq!
        node[key] = node["#{key}Ids"].count
        node['total'] += node[key]
      end
    end
  end

  def update_node(node_map, key, result)
    status_map = {'pass'=>'passed', 'fail'=>'failed','error'=>'errors', 'skip'=>'skipped'}
    node = node_map[key]
    if (node)
      result['status'] = 'error' if result['status'].nil?
      node[status_map[result['status']]] += 1
      node["#{status_map[result['status']]}Ids"] << result['id']
      node['total'] += 1
    else
      puts "\t KEY NOT FOUND: #{key}"
    end
  end

  def build_compliance_node_map(node, map)
    node_defaults = {
      'passed'=>0,'failed'=>0, 'errors'=>0, 'skipped'=>0, 'total'=>0,
      'passedIds'=>[],'failedIds'=>[], 'errorsIds'=>[], 'skippedIds'=>[]
    }
    raise "duplicate node: #{node['name']}" if map[node['name']]
    map[node['name']] = node.merge!(node_defaults)
    if node['children']
      node['children'].each do |child|
        build_compliance_node_map(child, map)
      end
    end
  end
end
