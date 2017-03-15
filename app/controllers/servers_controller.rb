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
    server = Server.where(url: url).first
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
    render json: {conformance: server.load_conformance(params[:refresh])}
  end

  def summary
    summary = Server.find(params[:server_id]).summary
    render json: {summary: summary}
  end

  def summary_history
    summaries = Summary.where({server_id: params[:server_id]})

    # Generate list of sundays
    sundays = (52.weeks.ago.to_date..Date.today).to_a.select {|k| k.wday == 0}

    # Put sundays into a hash and use to only save one data point per week
    sunday_index = sundays.inject({}) { |h,k| h[k] = nil; h}

    sections = {} # store the sections that we come across

    # loop through each summary and place in the sunday index
    summaries.each_entry do |e|

      #save the section names that we see for later use
      e.compliance['children'].each { |e| sections[e['name'].downcase] = {'passed' => 0, 'total' => 0}}

      # build the value for this run, which is a combination of the date and all the passed & total values for the categories
      value = e.compliance['children'].inject({'date' => e.generated_at.to_date}) {|h,k| h[k['name'].downcase] = {'passed' => k['passed'], 'total' => k['total']}; h}

      # if this is before our first sunday, and is after others stored in the first sunday, then have it register on the first sunday
      if e.generated_at < sundays.first  and (sunday_index[sundays.first].nil? or sunday_index[sundays.first]['date'] < e.generated_at.to_date)
        sunday_index[sundays.first] = value 
      end

      #figure out the next sunday from this date
      next_sunday = e.generated_at.to_date + (7 - e.generated_at.wday)

       # store this on the next sunday, as long as nothing from later in the week is already stored there
      if sunday_index[next_sunday].nil? or sunday_index[next_sunday]['date'] < e.generated_at.to_date
        sunday_index[next_sunday] = value
      end
    end

    # carry forward sundays with data to those without data
    sundays.inject(nil) {|p, k| sunday_index[k] = sunday_index[k] || p }

    # put the sunday_index into an array format for consumption by d3
    result = sunday_index.values

    # fix the dates on items to be on Sundays (since now it just stores the run date, not the date of the sunday)
    # include dates and section names with null values if the date has no data (happens on dates before the first run)
    sundays.each_with_index do |val, index| 
      if (result[index])
        result[index] = result[index].merge({'date'=>val})
      else
        result[index] = {'date' => val}.merge(sections)
      end
    end

    render json: result.to_json
  end

  def supported_tests
    server = Server.find(params[:server_id])
    @@suites ||= Test.where({multiserver: false}).sort {|l,r| l.name <=> r.name}
    @suites = @@suites

    server.collect_supported_tests rescue logger.error "error collecting supported tests"
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
      aggregate_run.results.select! {|r| r if r['status'] != 'pass'}
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
        :oath_token_opts, 
        :scopes, 
        :authorize_url, 
        :token_url, 
        :patient_id,
        :scopes
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
end
