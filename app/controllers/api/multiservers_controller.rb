module Api
  class MultiserversController < ApplicationController
    respond_to :json

    def index
      if current_user.nil?
        render json: Multiserver.all
      else
        render json: current_user.servers
      end
    end

    def create
      server = Multiserver.new(server_params)
      server.user = current_user
      if server.save
        respond_with server, location: api_servers_path
      else
        respond_with server, status: 422
      end
    end

    def show
      server = Multiserver.find(params[:id])
      respond_with server
    end

    def conformance
      binding.pry
    #   conformance = JSON.parse(FHIR::Client.new(params[:url]).conformanceStatement.to_json)
    #   conformance['rest'].each do |rest|
    #     rest['operation'] = rest['operation'].reduce({}) {|memo,operation| memo[operation['code']]=true; memo}
    #     rest['results'] = rest['operation'].reduce({}) {|memo,code| memo[code[0]]={:passed => [], :failed => [], :status => ""}; memo}
    #     rest['resource'].each do |resource|
    #       resource['operation'] = resource['operation'].reduce({}) {|memo,operation| memo[operation['code']]=true; memo}
    #       resource['results'] = resource['operation'].reduce({}) {|memo,code| memo[code[0]]={:passed => [], :failed => [], :status => ""}; memo}
    #     end
    #   end
    #   render json: conformance
    end

  private
    def server_params
      params.require(:multiserver).permit(:url1, :url2)
    end

  end
end
