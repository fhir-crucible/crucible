module Api
  class TestRunsController < ApplicationController
    respond_to :json

    def show
      test_run = TestRun.includes(:test_results).find(params[:id])
      test_run['test_results'] = test_run.test_results
      render json: {test_run: test_run}
    end


    def create
      run = TestRun.new(run_params)
      run.date = Time.now
      # run.user = current_user

      # params['test_run']['test_results'].each do |tr|
      #   test_result = TestResult.new()
      #   test_result.test_id = tr['test_id']
      #   test_result.test_run = run
      #   # test_result.save()
      #   run.test_results << test_result
      # end
      #
      if run.save()
      #   run['test_results'] = run.test_results
        run = {:test_run => run}
        respond_with run, location: api_test_runs_path
      # else
      #   run = {:test_run => run}
      #   respond_with run, status: 422
      end
    end

    def index
      @runs = []

      if not current_user.nil?
        @runs = current_user.test_runs
      end
      render json:{test_runs: @runs}
    end

    private
    def run_params
      params.require(:test_run).permit(:server_id)
    end
  end
end
