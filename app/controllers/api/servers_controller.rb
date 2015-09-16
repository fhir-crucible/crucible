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

    private

    def server_params
      params.require(:server).permit(:url, :name)
    end
  end
end
