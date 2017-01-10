class Server
  require 'json'

  attr_accessor :raw_conformance

  include Mongoid::Document
  field :name, type: String
  field :name_guessed, type: Boolean, default: false
  field :url, type: String
  belongs_to :summary
  has_one :aggregate_run
  field :percent_passing, type: Float
  field :conformance, type: String
  field :state, type: String
  field :client_id, type: String
  field :client_secret, type: String
  field :launch_param, type: String
  field :patient_id, type: String
  field :authorize_url, type: String
  field :token_url, type: String
  field :oauth_token_opts, type: Hash
  field :supported_tests, type: Array, default: []
  field :supported_suites, type: Array, default: []
  field :default_format, type: String
  field :tags, type: Array, default: []
  embeds_many :scopes
  field :last_run_at, type: Time
  field :fhir_sequence, type: String
  field :fhir_version, type: String
  field :hidden, type: Boolean, default: false

  def get_default_scopes
    [{ name: 'launch', description: 'Simulate an EHR launch profile', elem_id: 'launch_check' },
     { name: 'launch/patient', description: 'When launching outside the EHR, ask for a patient to be selected at launch time', selected: true},
     { name: 'patient/*.read', description: 'Permission to read any resource for the current patient', selected: true},
     { name: 'patient/Patient.read', description: 'Permission to read the Patient resource for the current patient'},
     { name: 'patient/DocumentReference.read', description: 'Permission to read DocumentReference resources for the current patient'},
     { name: 'patient/MedicationOrder.read', description: 'patient/MedicationOrder.read	Permission to read MedicationOrder resources for the current patient'},
     { name: 'patient/MedicationStatement.read', description: 'Permission to read MedicationStatemenet resources for the current patient'},
     { name: 'fhir_complete', description: 'Access to the entire FHIR API'},
     { name: 'user/Patient.read', description: 'Permission to read all Patient resources that the current user can access'},
     { name: 'user/*.read', description: 'Permission to read all resources that the current user can access'},
     { name: 'user/*.*', description: 'user/*.*	Permission to read and write all resources that the current user can access'},
     { name: 'openid profile', description: 'Permission to retrieve information about the current logged-in user'},
     { name: 'offline_access', description: 'Request a refresh_token that can be used to obtain a new access token to replace an expired one, even after the end-user no is longer online after the access token expires'},
     { name: 'online_access', description: 'Request a refresh_token that can be used to obtain a new access token to replace an expired one, and that will be usable for as long as the end-user remains online'}
    ]
  end

  def get_scopes
    # Support servers that don't have scopes set yet
    if scopes.empty?
      get_default_scopes.each do |scope_hash|
        scopes.create(scope_hash)
      end
    end
    scopes
  end

  def load_conformance(refresh=false)
    updated = false
    if (self.conformance.nil? || refresh)
      client = FHIR::Client.new(self.url)
      @raw_conformance ||= client.conformance_statement
      self.conformance = @raw_conformance.to_json
      self.supported_tests = []
      self.supported_suites = []
      collect_supported_tests
      self.default_format = client.default_format if client.default_format
      self.save!
      guess_name(true)
      extract_version_from_conformance
      updated = true
    end
    value = JSON.parse(self.conformance)
    value['updated'] = updated

    value['rest'].each do |rest|
      rest['operation'] = rest['operation'].reduce({}) {|memo,operation| memo[operation['name']]=true; memo} if rest['operation']
      rest['resource'].select {|r| !r['interaction'].nil?}.each do |resource|
        resource['operation'] = resource['interaction'].reduce({}) {|memo,operation| memo[operation['code']]=true; memo}
      end if rest['resource']
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
    if token.expired?
      if token.refresh_token
        token = token.refresh!
        if token
          self.oauth_token_opts = token.to_hash
          self.save!
        else
          return nil
        end
      else
        return nil
      end
    end
    return token
  end

  def get_compliance()
    #todo: investigate moving this elsewhere.
    compliance = Crucible::FHIRStructure.get

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
          result['created_at'] = test_result.created_at rescue nil
          result_map[id] = result.except('code', 'requests', :requests)
        end
      end
    end

    latest_results = aggregate_run.results.map {|result| (result_map.delete(result['id']) || result.except('code', 'requests', :requests)) }
    latest_results.concat(result_map.values)
    aggregate_run.results = latest_results
    aggregate_run.date = Time.now
    aggregate_run.save!
    self.save!
  end

  def available?
    begin
      available = (RestClient::Request.execute(:method => :get, :url => self.url+'/metadata', :timeout => 30, :open_timeout => 30, headers: {:accept => "#{FHIR::Formats::ResourceFormat::RESOURCE_JSON},#{FHIR::Formats::ResourceFormat::RESOURCE_XML},#{FHIR::Formats::ResourceFormat::RESOURCE_JSON_DSTU2},#{FHIR::Formats::ResourceFormat::RESOURCE_XML_DSTU2},application/xml,application/json"})).match /CapabilityStatement|Conformance/
      unless available
        return false
      end
    rescue
      return false
    end

    true
  end

  def collect_supported_tests
    # return if !self.supported_tests.empty? || !self.conformance
    translator = {'history-instance'=>'history', 'validate'=>'$validate', 'search-type' => 'search'}
    self.supported_tests = []
    self.supported_suites = []
    value = JSON.parse(self.conformance)

    operations = []
    resource_operations = []

    rest = value['rest'].first
    operations = rest['operation'].map {|o| "$#{o['name']}"} if rest['operation']
    resource_operations = Hash[rest['resource'].select{|r| !r['interaction'].nil?}.map{ |r| [r['type'], r['interaction'].map {|i| translator[i['code']] || i['code']}]}] if rest['resource']

    Test.all.each do |suite|
      at_least_one_test = false
      suite.methods.each do |test|
        supported = true
        test['requires'].each do |requirement|
          supported &&= check_restriction(requirement, resource_operations, operations)
        end if test['requires']
        test['validates'].each do |validation|
          supported &&= check_restriction(validation, resource_operations, operations)
        end if test['validates']
        if supported
          at_least_one_test = true
          self.supported_tests << test['id']
        end
      end
      self.supported_suites << suite.id if at_least_one_test
    end
    self.save!
  end

  def guess_name(force=false)
    return unless (self.name.blank? || (force && self.name_guessed))
    if self.conformance
      value = JSON.parse(self.conformance) rescue nil
      if value
        candidate = value['publisher'] || value['name']
        candidate ||= value['software']['name'] if value['software']
      end
    end
    if candidate.nil? || !candidate.is_a?(String)
      host = URI.parse(url).host rescue nil
      candidate = host.split('.').first if (host && (host =~ /\d+\.\d+\.\d+\.\d+/).nil?)
      candidate = host if (candidate.nil? || !(candidate =~ /^fhir/i).nil?)
      candidate ||= url
    end
    self.name_guessed = true
    self.name = candidate
    self.save
  end

  def extract_version_from_conformance
    if self.conformance
      value = JSON.parse(self.conformance) rescue nil
      if value
        self.fhir_version = value['fhirVersion']
        begin
          version_abbreviated = self.fhir_version
          version_abbreviated = self.fhir_version.split('-').first if self.fhir_version and self.fhir_version.include? '-'
          version = version_abbreviated.split('.').map(&:to_i)
          if version[0] >= 1 and version[1] >= 1
            self.fhir_sequence = 'STU3'
          elsif ['1.0.2', '1.0.1', '1.0.0', '0.5.0', '0.4.0', '0.40'].include? version_abbreviated
            self.fhir_sequence = 'DSTU2'
          elsif  ['0.0.82', '0.11', '0.06', '0.05'].include? version_abbreviated
            self.fhir_sequence = 'DSTU1'
          else
            self.fhir_sequence = ''
          end
        rescue
          self.fhir_sequence = ''
        end
        self.save
      end
    end
  end

  private

  def check_restriction(restriction, resource_operations, operations)
    resource = restriction['resource']
    if resource
      if !resource_operations.empty? && resource_operations[resource].nil?
        return false
      elsif !resource_operations.empty?
        if !((restriction['methods'] - resource_operations[resource]) - operations).empty?
          return false
        end
      end
    end
    true
  end


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
