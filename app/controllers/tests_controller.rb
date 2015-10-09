class TestsController < ApplicationController
  respond_to :json

  def index
    if !params[:multiserver].nil?
      @@multiserver_tests ||= Test.all.select{ |t| t.multiserver.to_s==params[:multiserver] }
      @tests = @@multiserver_tests
    else
      @@tests ||= Test.where({multiserver: false}).sort {|l,r| l.name <=> r.name}
      @tests = @@tests
    end

    render json:{tests: @tests}
  end

  def execute
    mtest = Test.find(params[:test_id])

    #todo check oath code
    # if server.oauth_code
    #   client1.client = server.get_oauth2_client
    #   client1.use_oauth2_auth = true
    # end

    result = nil
    success =  test_run.execute(mtest) do |r|
      result = r
    end

    if success
      render json: { tests: result.result }
    else 
      render json: {}
    end

  end

  private
end
