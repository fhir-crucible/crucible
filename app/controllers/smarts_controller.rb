require './config/oauth'

class SmartsController < ApplicationController
  before_filter :set_oauth

  def index
  end

  def app
    @app_params = params
    @app_session = session
    @invalid_launch = false
    @invalid_launch_state = false
    @other_launch_error = false
    if params['error']
      if params['error_uri']
        redirect_to params['error_uri']
      else
        @invalid_launch = true
      end
    elsif params['state'] != session[:state]
      @invalid_launch_state = true
    elsif params['state'].nil? || params['code'].nil? || session[:client_id].nil? || session[:token_url].nil? || session[:fhir_url].nil?
      @other_launch_error = true
    else
      start_time = Time.now
      # Get the OAuth2 token
      puts "App Params: #{params}"

      oauth2_params = {
        'grant_type' => 'authorization_code',
        'code' => params['code'],
        'redirect_uri' => Crucible::SMART::OAuth::OAUTH['redirect_url'],
        'client_id' => session[:client_id]
      }
      puts "Token Params: #{oauth2_params}"
      token_response = RestClient.post(session[:token_url], oauth2_params)
      token_response = JSON.parse(token_response.body)
      @token_response = token_response
      puts "Token Response: #{token_response}"
      token = token_response['access_token']
      patient_id = token_response['patient']
      scopes = token_response['scope']
      if scopes.nil?
        scopes = Crucible::SMART::OAuth.get_scopes(session[:fhir_url])
      end

      # Configure the FHIR Client
      client = FHIR::Client.new(session[:fhir_url])
      version = client.detect_version
      client.set_bearer_token(token)
      client.default_json

      smart = FHIR::SMART.new
      @report = smart.run_tests(client,scopes,patient_id)

      end_time = Time.now
      @time_diff = TimeDifference.between(start_time,end_time).humanize
    end

    render stream: true
  end

  def launch
    @launch_params = params
    if params && params['iss'] && params['launch']
      @valid_launch_params = true
      client_id = Crucible::SMART::OAuth.get_client_id(params['iss'])
      auth_info = Crucible::SMART::OAuth.get_auth_info(params['iss'])
      session[:client_id] = client_id
      session[:fhir_url] = params['iss']
      session[:authorize_url] = auth_info[:authorize_url]
      session[:token_url] = auth_info[:token_url]
      @fhir_url = params['iss']
      puts "Launch Client ID: #{client_id}\nLaunch Auth Info: #{auth_info}\nLaunch Redirect: #{Crucible::SMART::OAuth::OAUTH['redirect_url']}"
      session[:state] = SecureRandom.uuid
      oauth2_params = {
        'response_type' => 'code',
        'client_id' => client_id,
        'redirect_uri' => Crucible::SMART::OAuth::OAUTH['redirect_url'],
        'scope' => Crucible::SMART::OAuth.get_scopes(params['iss']),
        'launch' => params['launch'],
        'state' => session[:state],
        'aud' => params['iss']
      }
      oauth2_auth_query = "#{session[:authorize_url]}?"
      oauth2_params.each do |key,value|
        oauth2_auth_query += "#{key}=#{CGI.escape(value)}&"
      end
      puts "Launch Authz Query: #{oauth2_auth_query[0..-2]}"
      redirect_to oauth2_auth_query[0..-2]
    else
      @valid_launch_params = false
    end
  end

  def cfg
  end

  def update_cfg
    if params['delete']
      puts "Deleting configuration: #{params['delete']}"
      Crucible::SMART::OAuth.delete_client(params['delete'])
    else
      puts "Saving configuration: #{params}"
      Crucible::SMART::OAuth.add_client(params['Server'],params['Client ID'],params['Scopes'])
    end
    puts "Configuration saved."
    @config_data = Crucible::SMART::OAuth.get_config
    redirect_to "/smart/cfg"
  end

  private
  def set_oauth
    @config_data = Crucible::SMART::OAuth.get_config
  end
end
