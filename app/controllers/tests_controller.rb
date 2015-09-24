class TestsController < ApplicationController
  respond_to :json

  def index
    if !params[:multiserver].nil?
      @@multiserver_tests ||= Test.all.select{ |t| t.multiserver.to_s==params[:multiserver] }
      @tests = @@multiserver_tests
    else
      @@tests ||= Test.all.sort {|l,r| l.name <=> r.name}
      @tests = @@tests
    end

    render json:{tests: @tests}
  end

  def execute
    @server = Server.find(params[:server_id])
    client1 = FHIR::Client.new(@server.url)
    # client2 = FHIR::Client.new(result.test_run.destination_server.url) if result.test_run.is_multiserver
    # TODO: figure out multi server
    client2 = nil
    executor = Crucible::Tests::Executor.new(client1, client2)

    mtest = Test.find(params[:test_id])
    test = executor.find_test(mtest.title)

    val = nil
    if mtest.resource_class?
      val = test.execute(mtest.resource_class.constantize)[0]["#{result.test.title}_#{result.test.resource_class.split("::")[1]}"][:tests]
    else
      val = test.execute()[0][mtest.title][:tests]
    end

    # TODO: save results
    # result = TestResult.new
    test_run = TestRun.find(params[:test_result][:test_run_id])
    result = TestResult.new
    result.server_id = params[:server_id]
    result.test_id = params[:test_id]
    # TODO Remove this
    result.has_run = true

    # result.has_run = true
    result.result = val
    result.save
    test_run.test_results << result
    test_run.save
    # if we just executed a result and all the results have been run
    # TODO: this seems really really messy
    # if TestRun.find(result.test_run.id).test_results.all?(&:has_run)
    #   # build a summary for the run
    #   Compliance.build_compliance_json(result.test_run)
    # end

    render json: result.result

  end

  private
end
