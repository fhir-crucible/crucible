class ScorecardsController < ApplicationController

  # GET /scorecards
  def index
    @scorecards = [  ]
    @recent_scorecards = ScorecardRun.all.order_by(:date => :desc).limit(10)
    @top_scorecards = ScorecardRun.all.sort! { |a,b| b.get_score <=> a.get_score }[0..9]
  end

  # POST /scorecards/score_url
  def score_url
    @scorecards = []
    begin
      bundle_url = params['bundle_url']
      @message = bundle_url
      bundle_version = params['bundle_version']
      uri = URI(bundle_url)
      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https', :verify_mode => OpenSSL::SSL::VERIFY_NONE ) do |http|
        @my_request = Net::HTTP::Get.new uri
        @my_response = http.request @my_request # Net::HTTPResponse object
      end
      scorecard = FHIR::Scorecard.new
      @scorecards << scorecard.score(@my_response.body, bundle_version)
      @notice = 'Success'
      log(bundle_url)
    rescue OpenSSL::SSL::SSLError => s 
      @error = "SSL Error: #{s.message}"
      logger.error @error
    rescue Exception => e 
      @error = "Message: #{e.message}."
      logger.error @error
      logger.error e.message
      logger.error e.backtrace.join("\n    ")
    end
    render action: 'index'
  end

  # POST /scorecards/score_upload
  def score_upload
    @scorecards = []
    begin
      @message = params['bundle_contents'].original_filename
      body = params['bundle_contents'].read
      upload_version = params['upload_version']
      scorecard = FHIR::Scorecard.new
      @scorecards << scorecard.score(body, upload_version)
      @notice = 'Success'
    rescue Exception => e 
      @error = "Unable to parse file: #{e.message}"
      logger.error @error
    end
    log
    render action: 'index'    
  end

  # POST /scorecards/score_paste
  def score_paste
    @scorecards = []
    begin
      @message = "Copy & Pasted Bundle"
      body = params['bundle_body']
      paste_version = params['paste_version']
      scorecard = FHIR::Scorecard.new
      @scorecards << scorecard.score(body, paste_version)
      @notice = 'Success'
    rescue Exception => e 
      @error = "Unable to parse file: #{e.message}"
      logger.error @error
    end
    log
    render action: 'index'    
  end

  # GET /scorecards/<id>
  def show
    @scorecards = ScorecardRun.find(params["id"]).result
    render action: 'index'
  end

  def log(url=nil)
    ScorecardRun.new(url: url, result: @scorecards, date: Time.now).save
  end

end
