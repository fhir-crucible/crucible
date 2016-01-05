class ServersController < ApplicationController

  def show
    @server = Server.find(params[:id])

    currentTestRun = TestRun.where(server_id: @server.id).any_of([{ status: "pending" }, { status: "running" }]).first()
    @currentTestRunId = nil
    @currentTestRunId = currentTestRun.id unless currentTestRun.nil?

  end

  def create
    url = PostRank::URI.normalize(params['server']['url']).to_s
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
    server.update(server_params)
    server.name_guessed = false if server_params[:name]
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
        token = client.auth_code.get_token(params[:code], :redirect_uri => "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}/redirect", :headers=> {'Authorization' => "Basic #{auth_pw}"})
      else
        token = client.auth_code.get_token(params[:code], :redirect_uri => "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}/redirect")
      end
      if token.params["error"]
        flash.alert = "#{token.params['error']}: #{token.params['error_description']}"
        redirect_to server_path(server)
        return
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
    return unless aggregate_run
    if (params[:only_failures])
      aggregate_run.results.select! {|r| r if r['status'] != 'pass'}
    end
    render json: server.aggregate_run
  end

  def oauth_params
    server = Server.find(params[:server_id])
    if server
      server.client_id = params[:client_id]
      server.client_secret = params[:client_secret] unless server.client_secret && params[:client_secret] === '*' * server.client_secret.length
      server.state = params[:state]
      server.authorize_url = params[:authorize_url]
      server.token_url = params[:token_url]
      server.save
      render json: { success: true }
    end
  end

  private

  def server_params
    params.require(:server).permit(:url, :name)
  end
end
