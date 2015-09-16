module Api
  class TestsController < ApplicationController
    respond_to :json

    def index
      if !params[:multiserver].nil?
        @tests = Test.all.select{ |t| t.multiserver.to_s==params[:multiserver] }
      else
        @tests = Test.all
      end
      render json:{test: @tests}
    end

    def show
      render json: {test:Test.find(params[:id])}
    end
  end
end
