class ScorecardsController < ApplicationController

  # GET /scorecards
  def index
    @scorecards = []
  end

  # POST /scorecards/score_url
  def score_url
    @scorecards = []
    begin
      bundle_url = params['bundle_url']
      @message = bundle_url
      uri = URI(bundle_url)
      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https', :verify_mode => OpenSSL::SSL::VERIFY_NONE ) do |http|
        @my_request = Net::HTTP::Get.new uri
        @my_response = http.request @my_request # Net::HTTPResponse object
      end
      scorecard = FHIR::Scorecard.new
      @scorecards << scorecard.score(@my_response.body)
      @notice = 'Success'
    rescue OpenSSL::SSL::SSLError => s 
      @error = "SSL Error: #{s.message}"
      logger.error @error
    rescue Exception => e 
      @error = "Unable to parse response: #{response}"
      logger.error @error
    end
    render action: 'index'
  end

  # POST /scorecards/score_upload
  def score_upload
    @scorecards = []
    begin
      @message = params['bundle_contents'].original_filename
      body = params['bundle_contents'].read
      scorecard = FHIR::Scorecard.new
      @scorecards << scorecard.score(body)
      @notice = 'Success'
    rescue Exception => e 
      @error = "Unable to parse file: #{e.message}"
      logger.error @error
    end
    render action: 'index'    
  end

  # POST /scorecards/score_paste
  def score_paste
    @scorecards = []
    begin
      @message = "Copy & Pasted Bundle"
      body = params['bundle_body']
      scorecard = FHIR::Scorecard.new
      @scorecards << scorecard.score(body)
      @notice = 'Success'
    rescue Exception => e 
      @error = "Unable to parse file: #{e.message}"
      logger.error @error
    end
    render action: 'index'    
  end


end
