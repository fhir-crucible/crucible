module Api
  class TestResultsController < ApplicationController
    def result
      # run = TestRun.where('test_results._id' => BSON::ObjectId.from_string(params[:id])).first
      result = TestResult.find(params[:id])
      if result.has_run
        render json: {result: result.result}
      else
        client1 = FHIR::Client.new(result.test_run.server.url)
        client2 = FHIR::Client.new(result.test_run.destination_server.url) if result.test_run.is_multiserver
        executor = Crucible::Tests::Executor.new(client1, client2)
        test = executor.find_test(result.test.title)
        val = nil
        if result.test.resource_class?
          val = test.execute(result.test.resource_class.constantize)[0]["#{result.test.title}_#{result.test.resource_class.split("::")[1]}"][:tests]
        else
          val = test.execute()[0][result.test.title][:tests]
        end

        result.has_run = true
        result.result = val
        result.save()

        # if we just executed a result and all the results have been run
        if TestRun.find(result.test_run.id).test_results.all?(&:has_run)
          # build a summary for the run
          Compliance.build_compliance_json(result.test_run)
        end

        render json: {results: result.result}
      end
    end

  end
end
