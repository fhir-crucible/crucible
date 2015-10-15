class TestrunsController < ApplicationController
  respond_to :json

  def show
    test_run = TestRun.includes(:test_results).find(params[:id])
    test_run['test_results'] = test_run.test_results
    render json: {test_run: test_run}
  end

  def create
    run = TestRun.new(run_params)
    run.date = Time.now

    if run.save()
      run = {test_run: run}
      respond_with run, location: server_testruns_path
    end
  end

  def index
    @runs = []

    # if not current_user.nil?
    #   @runs = current_user.test_runs
    # end
    render json:{test_runs: @runs}
  end

  def execute
    server = Server.find(params[:server_id])
    test_run = TestRun.find(params[:testrun_id])
    tests = params[:test_ids].map {|t| Test.find(t) }
    finish = params[:finish] == "1"

    results = []

    success =  test_run.execute(tests) do |result|
      results << result
    end

    summary = nil

    if finish
      summary = test_run.finish()
    end

    render json: {success: success, test_results: results, summary: summary}

  end

  def finish
    server = Server.find(params[:server_id])
    test_run = TestRun.find(params[:testrun_id])
    summary = test_run.finish()

    render json: {summary: summary}
  end

  private
  def run_params
    params.require(:test_run).permit(:server_id)
  end

end
