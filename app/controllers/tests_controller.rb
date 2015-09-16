class TestsController < ApplicationController
  respond_to :json


  def index
    list = []
    index = 0

    # Receives:

    # {:ReadTest=>
    #   {:author=>"Crucible::Tests::ReadTest",
    #    :description=>"Initial Sprinkler tests (R001, R002, R003, R004) for testing basic READ requests.",
    #    :title=>"ReadTest",
    #    :tests=>
    #     [:r001_get_person_data_test,
    #      :r002_get_unknown_resource_type_test,
    #      :r003_get_non_existing_resource_test,
    #      :r004_get_bad_formatted_resource_id_test]
    #   }
    # }

    Crucible::Tests::Executor.list_all.each do |k,v|
      list << {id: index+=1}.merge(v)
    end
    tests = {tests: list}
    respond_with JSON.pretty_generate(tests)

    # Returns:

    # http://localhost:3000/tests

    # {
    #   "tests": [
    #     {
    #       "id": 1,
    #       "author": "Crucible::Tests::ReadTest",
    #       "description": "Initial Sprinkler tests (R001, R002, R003, R004) for testing basic READ requests.",
    #       "title": "ReadTest",
    #       "tests": [
    #         "r001_get_person_data_test",
    #         "r002_get_unknown_resource_type_test",
    #         "r003_get_non_existing_resource_test",
    #         "r004_get_bad_formatted_resource_id_test"
    #       ]
    #     }
    #   ]
    # }
  end

  def conformance
    params[:url] ||= 'http://fhir.healthintersections.com.au/open' # valid endpoint, commented to prevent spamming
    val = { debug: params, results: JSON.parse(FHIR::Client.new(params[:url]).conformanceStatement.to_json)}
    respond_with JSON.pretty_generate(val)
  end

  def execute_all
    params[:url] ||= 'http://fhir.healthintersections.com.au/open' # valid endpoint, commented to prevent spamming
    # params[:url] ||= 'http://fhir.healthintersections.com.au/'
    val = { debug: params, results: Crucible::Tests::Executor.new(FHIR::Client.new params[:url]).execute_all }
    respond_with JSON.pretty_generate(val)

    # Returns:

    # http://localhost:3000/tests/execute_all

    # {
    #   "debug": {
    #     "format": "json",
    #     "controller": "tests",
    #     "action": "execute_all",
    #     "url": "http://fhir.healthintersections.com.au/"
    #   },
    #   "results": {
    #     "ReadTest": {
    #       "test_file": "ReadTest",
    #       "tests": {
    #         "r001_get_person_data_test": {
    #           "test_method": "r001_get_person_data_test",
    #           "status": "passed",
    #           "result": null
    #         },
    #         "r002_get_unknown_resource_type_test": {
    #           "test_method": "r002_get_unknown_resource_type_test",
    #           "status": "missing",
    #           "result": "r002_get_unknown_resource_type_test failed. Error: Implementation missing: r002_get_unknown_resource_type_test."
    #         },
    #         "r003_get_non_existing_resource_test": {
    #           "test_method": "r003_get_non_existing_resource_test",
    #           "status": "missing",
    #           "result": "r003_get_non_existing_resource_test failed. Error: Implementation missing: r003_get_non_existing_resource_test."
    #         },
    #         "r004_get_bad_formatted_resource_id_test": {
    #           "test_method": "r004_get_bad_formatted_resource_id_test",
    #           "status": "missing",
    #           "result": "r004_get_bad_formatted_resource_id_test failed. Error: Implementation missing: r004_get_bad_formatted_resource_id_test."
    #         }
    #       }
    #     }
    #   }
    # }

  end

  def execute
    params[:title] ||= 'BaseTest'
    url = params[:url] || params[:url1]
    url ||= 'http://fhir.healthintersections.com.au/open' # valid endpoint, commented to prevent spamming
    client1 = FHIR::Client.new(url)
    client2 = FHIR::Client.new(params[:url2]) if params[:url2]

    test = Crucible::Tests.const_get(params[:title]).new(client1, client2)

    if params[:resource_class]
      val = { debug: params, results: test.execute(params[:resource_class].constantize) }
    else
      val = { debug: params, results: test.execute }
    end

    respond_with JSON.pretty_generate(val)

    # Returns:

    # http://localhost:3000/tests/execute/ReadTest

    # {
    #   "debug": {
    #     "format": "json",
    #     "controller": "tests",
    #     "action": "execute",
    #     "title": "ReadTest",
    #     "url": "http://fhir.healthintersections.com.au/"
    #   },
    #   "results": {
    #     "r001_get_person_data_test": {
    #       "test_method": "r001_get_person_data_test",
    #       "status": "passed",
    #       "result": null
    #     },
    #     "r002_get_unknown_resource_type_test": {
    #       "test_method": "r002_get_unknown_resource_type_test",
    #       "status": "missing",
    #       "result": "r002_get_unknown_resource_type_test failed. Error: Implementation missing: r002_get_unknown_resource_type_test."
    #     },
    #     "r003_get_non_existing_resource_test": {
    #       "test_method": "r003_get_non_existing_resource_test",
    #       "status": "missing",
    #       "result": "r003_get_non_existing_resource_test failed. Error: Implementation missing: r003_get_non_existing_resource_test."
    #     },
    #     "r004_get_bad_formatted_resource_id_test": {
    #       "test_method": "r004_get_bad_formatted_resource_id_test",
    #       "status": "missing",
    #       "result": "r004_get_bad_formatted_resource_id_test failed. Error: Implementation missing: r004_get_bad_formatted_resource_id_test."
    #     }
    #   }
    # }

  end

end