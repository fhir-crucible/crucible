class TestrunsController < ApplicationController
  respond_to :json

  def show
    test_run = TestRun.includes(:test_results).find(params[:id])
    test_run['test_results'] = test_run.test_results
    render json: {test_run: test_run}
  end

  def create
    run = TestRun.new({server_id: params[:server_id], date: Time.now})
    tests = params[:test_ids].map {|i| Test.find(i)}

    run.add_tests(tests)
    RunTestsJob.perform_later(run.id.to_s)

    render json: { test_run: run }
  end
end
