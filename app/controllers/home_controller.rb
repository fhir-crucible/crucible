class HomeController < ApplicationController
  # before_action :authenticate_user!

  def index
    #@servers = Server.all.order_by("percent_passing"=>:desc)
    # show all until issue is resolved
    @servers = Server.where({percent_passing: {"$gte" => 0}}).order_by("percent_passing"=>:desc)
  end

  def server_scrollbar_data

    total_tests = Test.all.inject([]) { |a,i| a.concat i.methods}.count
    servers = Server.where({percent_passing: {"$gte" => 0}}).map do |server|
      {
        id: server._id.to_s,
        name: server.name,
        percent_passing: server.percent_passing
      }
    end

    render json: {total_tests: total_tests, servers: servers}
  end


end
