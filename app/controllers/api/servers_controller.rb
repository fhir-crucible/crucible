module Api
  class ServersController < ApplicationController
    respond_to :json

    def update
      server = Server.find(params[:id])
      server.update(server_params)
      if server.save
        respond_with server
      else
        respond_with server, status: 422
      end
    end

    def conformance
      server = Server.find(params[:id])
      render json: {conformance: server.load_conformance(params[:refresh])}
    end

    def summary
      summary = Server.find(params[:id]).summary
      render json: {summary: summary}
    end

    def aggregate_run
      server = Server.find(params[:id])
      aggregate_run = server.aggregate_run
      return unless aggregate_run
      if (params[:only_failures])
        aggregate_run.results.select! {|r| r if r['status'] != 'pass'}
      end
      render json: server.aggregate_run
    end

    def generate_summary
      test_run = TestRun.find(params[:test_run_id])
      summary = test_run.finish()

      render json: {summary: summary}
    end

    def oauth_params
      server = Server.find(params[:id])
      if server
        server.client_id = params[:client_id]
        server.client_secret = params[:client_secret]
        server.state = params[:state]
        server.authorize_url = params[:authorize_url]
        server.token_url = params[:token_url]
        server.save
        render json: { success: true }
        # render status: 500, text: 'Error'
      end
    end

    private

    def server_params
      params.require(:server).permit(:url, :name)
    end
  end
end
