class HomeController < ApplicationController
  # before_action :authenticate_user!

  def index
    #@servers = Server.all.order_by("percent_passing"=>:desc)
    # show all until issue is resolved
    @servers = Server.where({percent_passing: {"$gte" => 0}}).order_by("percent_passing"=>:desc)
  end

  def server_scrollbar_data

    total_tests = Test.all.inject([]) { |a,i| a.concat i.methods}.count
    servers = Server.where({percent_passing: {"$gte" => 0}}).includes(:summary).all.map do |server|
      if server.summary and server.summary['compliance'] and server.summary['compliance']['total']
        compliance = server.summary['compliance']
        {
          id: server._id.to_s,
          name: server.name,
          percent_run: compliance['total'].to_f / total_tests.to_f,
          compliance: 0.8,
          score: compliance['passed'].to_f / compliance['total'].to_f,
          total: compliance['total'].to_f
        }
      end
    end

    render json: {total_tests: total_tests, servers: servers.reject {|s| s.nil?}}
  end


end
