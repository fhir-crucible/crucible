class DashboardsController < ApplicationController

  def show
    @id = params[:id]
    @dashboard = Dashboard.where(tag: @id).first
    @suites = Test.where({tags: @id}).sort! {|l,r| l.name <=> r.name}
  end

	def results

    id = params[:dashboard_id]
    servers = Server.where({tags: id}).map {|s| s}
    suites = Test.where({tags: id}).map {|s| s}

    results = {}
    has_results = {}
    test_result_ids = []
    servers.each do |server|
      suites.each do |suite|
        test_ids = suite.methods.map {|m| m['id']}
        test_results = []
        last_updated = nil;
        if server.aggregate_run
          test_results = server.aggregate_run.results.select {|r| test_ids.include? r['id']}
          last_updated = test_results.map {|r| r['created_at']}.compact.min
          has_results[server.id.to_s] ||= !test_results.empty?
          test_result_ids.concat test_results.map {|t| t["test_result_id"]}
        end
        results[server.id.to_s] ||= {}
        results[server.id.to_s][suite.id.to_s] = {results: test_results, last_updated: last_updated}
      end
    end
    backfill_requests(test_result_ids, results)

    servers.sort! {|l,r| compare_servers(l, r, has_results)}

    render json: {servers: servers.map {|s| s.attributes.except('conformance', 'supported_tests', 'supported_suites')}, suites: suites, resultsByServer: results}

	end

  private

  def compare_servers(left, right, has_results)
    if (has_results[left.id.to_s] == has_results[right.id.to_s])
      left.name <=> right.name
    elsif (has_results[left.id.to_s])
      -1
    else
      1
    end
  end

  def backfill_requests(test_result_ids, results)
    test_results_by_id = {}
    TestResult.find(test_result_ids).each {|tr| test_results_by_id[tr.id] = tr} rescue 'missing results'
    results.values.each do |by_suite|
      by_suite.values.each do |trs|
        trs[:results].each do |tr|
          tr['requests'] = test_results_by_id[tr['test_result_id']].result.select{|x| x['id'] == tr['id']}.first['requests'] if test_results_by_id[tr['test_result_id']]
        end
      end
    end
  end

end
