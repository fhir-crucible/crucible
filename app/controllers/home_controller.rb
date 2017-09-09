class HomeController < ApplicationController
  # before_action :authenticate_user!

  def index
    #@servers = Server.all.order_by("percent_passing"=>:desc)
    # show all until issue is resolved
    @servers = Server.where({percent_passing: {"$gte" => 0}, hidden: {"$ne" => true}})
                     .only(:id, :name, :last_run_at, :url, :active, :fhir_sequence, :fhir_version, :percent_passing)
                     .order_by("percent_passing"=>:desc)
    @server_count = Server.count
    @test_run_count = TestRun.count

    @test_suites = Test.count
    @tests_available = Test.each.inject(0) { |sum, n| sum + n[:methods].length }
    @tests_count = Statistics.try(:first).try(:tests_run) || 0

  end

  def server_scrollbar_data

    total_tests = Test.all.inject([]) { |a,i| a.concat i.methods}.count
    servers = Server.where({percent_passing: {"$gte" => 0}, hidden: {"$ne" => true}}).only(:id, :name, :percent_passing).map do |server|
      {
        id: server._id.to_s,
        name: server.name,
        percent_passing: server.percent_passing
      }
    end

    render json: {total_tests: total_tests, servers: servers}
  end

  def calendar_data
    tests_by_date = TestRun.collection.aggregate(
      [
        { "$match" => { 'nightly' => false } },
        { "$group" =>
         {
           :_id => { :day => { "$dayOfYear" => "$date"}, :year => { "$year" => "$date" } },
           :count => { "$sum" => 1 }
         }
       }
      ] 
    )
    render json: { tests_by_date: tests_by_date }
  end

  def bar_chart_data
    test_frequency = TestRun.collection.aggregate([
        { "$match" => { 'nightly' => false } },
        #  :date => { "$gt" => Date.today.prev_month } }
        { "$unwind" => "$test_ids" },
        { "$group" => {
            "_id" => "$test_ids",
            "count" => { "$sum" => 1 }
        }},
        { "$sort" => { "count" => -1 }},
        { "$limit" => 10 }
    ])

    render json: { test_frequency: test_frequency }

  end

end
