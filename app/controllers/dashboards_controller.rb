class DashboardsController < ApplicationController

  def show
    @id = params[:id]
    @suites = Test.where({tags: @id}).sort! {|l,r| l.name <=> r.name}
  end

	def results

    id = params[:dashboard_id]
    servers = Server.where({tags: id}).map {|s| s}
    suites = Test.where({tags: id}).map {|s| s}

    results = {}
    servers.each do |server|
      suites.each do |suite|
        test_ids = suite.methods.map {|m| m['id']}
        test_results = server.aggregate_run.results.select {|r| test_ids.include? r['id']}
        results[server.id.to_s] ||= {}
        results[server.id.to_s][suite.id.to_s] = test_results
      end
    end

    render json: {servers: servers.map {|s| s.attributes.except('conformance', 'supported_tests', 'supported_suites')}, suites: suites, resultsByServer: results}

	end

end