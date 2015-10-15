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
end
