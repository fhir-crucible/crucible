class ServersController < ApplicationController

  def show
    @server = Server.find(params[:id])

    currentTestRun = TestRun.where(server_id: @server.id).any_of([{ status: "pending" }, { status: "running" }]).first()
    @currentTestRunId = nil
    @currentTestRunId = currentTestRun.id unless currentTestRun.nil?

  end

  def create
    url = Addressable::URI.parse(params['server']['url']).normalize.to_s
    url = url.chop if url[-1] == '/'
    server = Server.where(url: url).order_by("hidden" => :asc).first
    unless server
      server = Server.new(params.require(:server).permit(:name))
      server.url = url
      server.guess_name
      server.save
    end
    redirect_to action: "show", id: server.id
  end

  def update
    server = Server.find(params[:id])
    params[:server][:tags] = params[:server][:tags].split(",").map(&:strip)
    server.update(server_params)
    server.name_guessed = false if server_params[:name]
    server.guess_name # will only change if blank
    if server.save
      render json: {server: server}
    else
      render json: {}, status: 422
    end
  end

  def oauth_redirect
    server = Server.where(state: params[:state]).first
    if server
      options = {
        authorize_url: server.authorize_url,
        token_url: server.token_url,
        raise_errors: false
      }
      if params['error'] || params['error_description']
        flash.alert = "Authorization error: #{params['error_description']}"
        redirect_to server_path(server)
        return
      end
      client = OAuth2::Client.new(server.client_id, server.client_secret, options)
      if (!server.client_secret.empty?)
        auth_pw = Base64.strict_encode64("#{server.client_id}:#{server.client_secret}")
        token_params = {
          redirect_uri: "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}/redirect",
          code: params[:code],
          grant_type: "authorization_code",
        }
        response = client.request(:post, server.token_url, {:body => token_params, :headers => {'Authorization' => "Basic #{auth_pw}"}})
        token = OAuth2::AccessToken.from_hash(client, JSON.parse(response.body))
      else
        token = client.auth_code.get_token(params[:code], :redirect_uri => "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}/redirect")
      end
      if token.params["error"]
        flash.alert = "#{token.params['error']}: #{token.params['error_description']}"
        redirect_to server_path(server)
        return
      end

      if !token.params["patient"] && server.patient_id
        token.params["patient"] = server.patient_id
      end

      server.oauth_token_opts = token.to_hash
      server.save!
      flash.notice = "Server successfully authorized"
      redirect_to server_path(server)

    else
      render status: 500, text: 'State not found'
    end

  end

  def conformance
    server = Server.find(params[:server_id])
    conformance = server.load_conformance(params[:refresh])

    render json: {
      conformance: conformance,
      crucible_fhir_version: Rails.application.config.fhir_version,
      crucible_fhir_sequence: Rails.application.config.fhir_sequence,
      fhir_version: server.fhir_version,
      fhir_sequence: server.fhir_sequence,
    }
  end

  def summary
    server = Server.where(_id: params[:server_id]).only(:fhir_sequence, :summary).first
    fhir_sequence = server.fhir_sequence || 'STU3'
    summary = server.summary
    render json: {summary: summary, fhir_sequence: fhir_sequence}
  end

  def summary_history
    server = Server.find(params[:server_id])

    sundays = (51.weeks.ago.to_date..(sunday_after(Date.today))).to_a.select {|k| k.wday == 0}
    server.history.reject! do |entry|
      sundays.exclude?(entry["date"]) && entry['date'] < Date.today
    end

    if server.history.length == 0 || params[:regenerate]
      server.generate_history
    end

    sundays.reject! {|sunday| server.history.select{|entry| entry["date"] == sunday}.length > 0}

    last_sunday = server.history.last

    sundays.each do |sunday|
      server.history << last_sunday.clone
      server.history.last['date'] = sunday
    end

    server.history.last['date'] = Time.parse(Date.today.to_s).utc #mark the last entry as today's date instead of next sunday

    render json: server.history.to_json
  end

  def supported_tests
    server = Server.find(params[:server_id])
    @suites = Test.where({multiserver: false}).sort {|l,r| l.name <=> r.name}

    server.collect_supported_tests rescue logger.error "error collecting supported tests"

    server_version = (server.fhir_sequence || 'STU3').downcase.to_sym
    @suites.select!{|s| s.supported_versions.include? server_version}

    if server.supported_suites
      @suites.each do |suite|
        if server.supported_suites.include? suite.id
          suite.supported = true
          suite.methods.each do |test|
            test['supported'] = true if server.supported_tests.include? test['id']
          end
        end
      end
      has_conformance = true
    end

    render json:{tests: @suites}
  end

  def past_runs
    server = Server.find(params[:server_id])
    past_runs = TestRun.where(server: server, status: 'finished').order_by(:date => 'desc')
    render json: {past_runs: past_runs}
  end

  def aggregate_run
    server = Server.find(params[:server_id])
    aggregate_run = server.aggregate_run
    render :nothing => true unless aggregate_run
    return unless aggregate_run
    if (params[:only_failures])
      tests = Test.all.map{|m| m} # force mongo to load all these into memory
      aggregate_run.results.select! {|r| r if r['status'] == 'fail' && tests.any? {|t| t["_id"] == r['test_id']} && server.supported_tests.include?(r['id'])}
    end
    render json: aggregate_run
  end

  def oauth_params
    server = Server.find(params[:server_id])
    if server
      server.client_id = params[:client_id].strip
      server.client_secret = params[:client_secret].strip unless server.client_secret && params[:client_secret] === '*' * server.client_secret.length
      server.state = params[:state]
      server.authorize_url = params[:authorize_url]
      server.token_url = params[:token_url]
      server.launch_param = params[:launch_param] ? params[:launch_param].strip : ''
      server.patient_id = params[:patient_id] ? params[:patient_id].strip : ''
      if params[:scopes]
        scopes = params[:scopes].split(",")
        server.scopes.find_all { |scope| scopes.index(scope.name) }. each do |scope|
          scope.update_attribute(:selected, true)
        end
      end
      server.save
      render json: { success: true }
    end
  end

  def delete_authorization
    server = Server.find(params[:server_id])
    if server
      server.unset(
        :token,
        :client_id,
        :client_secret,
        :oauth_token_opts,
        :scopes,
        :authorize_url,
        :token_url,
        :patient_id,
        :scopes,
        :launch_param
      )
      server.save
      flash.notice = "Server authorization credentials deleted"
    end
    render json: { success: true }
  end

  private

  def server_params
    params.require(:server).permit(:url, :name, tags: [])
  end

  def sunday_after(date)
    date + (7-date.wday)
  end

end
