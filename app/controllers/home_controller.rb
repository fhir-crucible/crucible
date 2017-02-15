class HomeController < ApplicationController
  # before_action :authenticate_user!

  def index
    #@servers = Server.all.order_by("percent_passing"=>:desc)
    # show all until issue is resolved
    @servers = Server.where({percent_passing: {"$gte" => 0}, fhir_sequence: Rails.application.config.fhir_sequence, hidden: {"$ne" => true}}).order_by("percent_passing"=>:desc)
    @server_count = Server.count
    @test_run_count = TestRun.where({ nightly: false}).count

    @test_suites = Test.count
    @tests_available = 0
    Test.each do |document|
      @tests_available += document[:methods].length
    end

    @tests_by_date = TestRun.collection.aggregate(
      [
        { "$match" => { 'nightly' => false } },
        { "$group" =>
         {
           :_id => { :day => { "$dayOfYear" => "$date"}, :year => { "$year" => "$date" } },
           :count => { "$sum": 1 }
         }
       }
      ] 
    )
    @tests_json = @tests_by_date.to_json()

    @test_frequency = TestRun.collection.aggregate([
        { "$match" => { 'nightly' => false , 
          :date => { "$gt" => Date.today.prev_month } }
        },
        { "$unwind": "$test_ids" },
        { "$group": {
            "_id": "$test_ids",
            "count": { "$sum": 1 }
        }},
        { "$sort": { "count" => -1 }},
        { "$limit" => 10 }
    ]).to_json()
  end

  def server_scrollbar_data

    total_tests = Test.all.inject([]) { |a,i| a.concat i.methods}.count
    servers = Server.where({percent_passing: {"$gte" => 0}, fhir_sequence: Rails.application.config.fhir_sequence, hidden: {"$ne" => true}}).map do |server|
      {
        id: server._id.to_s,
        name: server.name,
        percent_passing: server.percent_passing
      }
    end

    render json: {total_tests: total_tests, servers: servers}
  end


end
