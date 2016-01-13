class TestResultsController < ApplicationController
  def show
    test_result = TestResult.find(params[:id])
    render json: {test_result: test_result}
  end

  def reissue_request
    test_result = TestResult.find(params[:test_result_id])
    test_id = params[:test_id]
    request_index = params[:request_index].to_i
    result = test_result.reissue_request(test_id, request_index)
    render json: result
  end
end
