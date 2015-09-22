module Api
  class ServersController < ApplicationController
    respond_to :json

    def index
      if current_user.nil?
        render json: Server.all
      else
        render json: current_user.servers
      end
    end

    def create
      server = Server.where(url: params['server']['url'], user: current_user).first
      unless server
        puts "!!Creating Servers!!"
        server = Server.new(server_params)
        server.user = current_user
      end

      if server.save
        respond_with server, location: api_servers_path
      else
        respond_with server, status: 422
      end
    end

    def show
      server = Server.find(params[:id])
      respond_with server
    end

    def update
      # Unauthenticated users can't update.
      unless current_user
        head :forbidden
        return
      end
      server = Server.find(params[:id])
      server.update(server_params)
      if server.save
        respond_with server, location: api_servers_path
      else
        respond_with server, status: 422
      end
    end

    def destroy
      # Unauthenticated users can't delete.
      unless current_user
        head :forbidden
        return
      end
      server = Server.find(params[:id])
      server.destroy

      respond_with server, location: api_servers_path
    end

    def conformance
      server = Server.find(params[:id])
      conformance = server.load_conformance
      render json: {conformance: conformance}
    end

    def summary
      render json: {summary:Summary.where(server_id: params[:id]).try(:last)}
    end

    def generate_summary

      test_run = TestRun.where(server_id: params[:id]).order_by(date: 'desc').first
      server = Server.find(params[:id])
      if test_run.date <= server.summary.generated_at
        render json: {summary: server.summary}
        return
      end
      summary = Compliance.build_compliance_json(test_run)


      server.summary = summary
      server.percent_passing = (summary.compliance['passed'].to_f / summary.compliance['total'].to_f) * 100.0
      server.save
      render json: {summary: summary}
    end

    private

    def server_params
      params.require(:server).permit(:url, :name)
    end
  end
end
