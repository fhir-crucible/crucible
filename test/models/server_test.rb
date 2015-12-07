require_relative '../test_helper'

class ServerTest < ActiveSupport::TestCase

  def setup
    dump_database
    @conformance_xml = File.read(Rails.root.join('test','fixtures','xml','conformance', 'bonfire_conformance.xml'))
    @partial_conformance_json = File.read(Rails.root.join('test','fixtures','json','conformance','partial_conformance.json'))
  end

  def test_load_conformance
    server = Server.new ({url: 'www.example.com'})

    assert_nil server.conformance

    stub = stub_request(:get, "www.example.com/metadata").to_return(body: @conformance_xml).times(1)
    conformance = server.load_conformance

    assert_not_nil conformance['rest']
    assert_not_nil server.conformance

    # will fail if we request again
    conformance = server.load_conformance

  end

  def test_generate_state
    server = Server.new ({url: 'www.example.com'})
    assert_not_nil server.generate_state
  end

  def test_available?
    server = Server.new ({url: 'www.example.com'})
    stub = stub_request(:get, "www.example.com/metadata").to_return(body: @conformance_xml).times(1)
    assert server.available?

    stub = stub_request(:get, "www.example.com/metadata").to_timeout.times(1)
    assert_not server.available?

    stub = stub_request(:get, "www.example.com/metadata").to_return(status: 500)
    assert_not server.available?

    stub = stub_request(:get, "www.example.com/metadata").to_return(body: '<html></html>')
    assert_not server.available?

  end

  def test_collect_supported_tests
    conformance = FHIR::Conformance.from_fhir_json(@partial_conformance_json)
    server = Server.new ({url: 'www.example.com'})

    stub = stub_request(:get, "www.example.com/metadata").to_return(body: @partial_conformance_json).times(4)
    conformance = server.load_conformance

    server.collect_supported_tests
    
    someSuites = ["readtest", "format001", "resourcetest_allergyintolerance", "resourcetest_appointment", "searchtest_allergyintolerance",
                  "resourcetest_condition", "resourcetest_conformance", "resourcetest_observation", "resourcetest_patient", "resourcetest_practitioner",
                  "resourcetest_schedule", "resourcetest_slot", "searchtest_condition", "searchtest_observation", "searchtest_patient", "search001"]

    someTests = ["R002", "X000_Medication", "X020_Medication", "X000_MedicationOrder", "X020_MedicationOrder", "S000_Medication", "S001P_Medication",
                 "S003P_Medication", "SE01P_Medication", "S001G_Medication", "S003G_Medication", "SE01G_Medication"]

    excludedSuites = ["connectathonfinancialtracktest", "connectathonterminologytracktest", "history001", "resourcetest_account", "resourcetest_appointmentresponse",
                     "resourcetest_auditevent", "searchtest_procedure", "searchtest_procedurerequest", "searchtest_processrequest", "searchtest_processresponse",
                     "searchtest_provenance"]

    excludedTests = ["R005", "X010_Medication", "X030_Medication", "X040_Medication", "X050_Medication", "X055_Medication",
                     "HI04", "HI06", "S003P_ProcedureRequest", "SE01P_ProcedureRequest"]

    assert_equal someSuites.length, (server.supported_suites & someSuites).length
    assert_equal someTests.length, (server.supported_tests & someTests).length

    assert_equal 0, (server.supported_suites & excludedSuites).length
    assert_equal 0, (server.supported_tests & excludedTests).length
  end

  def test_aggregate
    collection_fixtures('servers', 'test_results', 'test_runs')
    server = Server.where({name: 'tested_server'}).first
    assert_nil server.aggregate_run

    full_run = TestRun.find('560f068c4d4d3266f8840200')
    partial_run = TestRun.find('560f068c4d4d3266f8840201')
    
    assert server.aggregate(partial_run)
    assert_not_nil server.aggregate_run
    assert_equal TestResult.where({test_run_id: partial_run.id}).map(&:result).flatten.count, server.aggregate_run.results.count

    assert_equal 'fail', server.aggregate_run.results.select {|x| x['id'] == 'HI01'}.first['status']
    assert_equal 'fail', server.aggregate_run.results.select {|x| x['id'] == 'R001'}.first['status']
    assert_equal 'pass', server.aggregate_run.results.select {|x| x['id'] == 'X000_Binary'}.first['status']
    assert_equal 'pass', server.aggregate_run.results.select {|x| x['id'] == 'X000_Basic'}.first['status']

    assert server.aggregate(full_run)
    assert_not_nil server.aggregate_run
    assert_equal TestResult.where({test_run_id: full_run.id}).map(&:result).flatten.count, server.aggregate_run.results.count
    assert_equal 'pass', server.aggregate_run.results.select {|x| x['id'] == 'HI01'}.first['status']
    assert_equal 'pass', server.aggregate_run.results.select {|x| x['id'] == 'R001'}.first['status']
    assert_equal 'fail', server.aggregate_run.results.select {|x| x['id'] == 'X000_Binary'}.first['status']
    assert_equal 'pass', server.aggregate_run.results.select {|x| x['id'] == 'X000_Basic'}.first['status']
    assert_equal 'pass', server.aggregate_run.results.select {|x| x['id'] == 'X000_EligibilityRequest'}.first['status']

    # check aggregate serializable hash
    assert (JSON.parse(server.aggregate_run.to_json).keys & ['_id']).empty?

  end

  def test_get_compliance
    collection_fixtures('servers', 'test_results', 'test_runs')
    server = Server.where({name: 'tested_server'}).first

    full_run = TestRun.find('560f068c4d4d3266f8840200')
    partial_run = TestRun.find('560f068c4d4d3266f8840201')

    # check test run serializable hash
    assert (JSON.parse(partial_run.to_json).keys & ['_id']).empty?

    
    assert server.aggregate(partial_run)

    compliance = server.get_compliance

    assert_equal 120, compliance['total']
    assert_equal 103, compliance['passed']
    assert_equal 13, compliance['failed']
    assert_equal 2, compliance['skipped']
    assert_equal 2, compliance['errors']

    operations = compliance['children'].select {|x| x['name'] == 'OPERATIONS'}.first
    assert_equal 103, operations['passedIds'].count
    assert_equal 4, (operations['passedIds'] & ["R003", "HI03", "X000_Binary", "FT02"]).count
    assert_equal 103, operations['passed']
    assert_equal 2, operations['skippedIds'].count
    assert_equal 2, (operations['skippedIds'] & ["X020_Account", "X050_AllergyIntolerance"]).count
    assert_equal 2, operations['skipped']
    assert_equal 13, operations['failedIds'].count
    assert_equal 7, (operations['failedIds'] & ["R001", "R004", "R005", "X030_AuditEvent", "HI06", "HI08", "HI11"]).count
    assert_equal 13, operations['failed']

    extensions = compliance['children'].select {|x| x['name'] == 'EXTENSIONS'}.first
    assert_equal 1, (extensions['skippedIds'] & ["X050_AllergyIntolerance"]).count
    assert_equal 1, extensions['skipped']
    assert_equal 1, extensions['total']

    format = compliance['children'].select {|x| x['name'] == 'FORMAT'}.first
    assert_equal 4, (format['passedIds'] & ["CT02B","FT04D","CT04A","FT06C"]).count
    assert_equal 22, format['passed']
    assert_equal 22, format['total']

    assert server.aggregate(full_run)

    compliance = server.get_compliance

    assert_equal 1895, compliance['total']
    assert_equal 1508, compliance['passed']
    assert_equal 371, compliance['failed']
    assert_equal 16, compliance['skipped']
    assert_equal 0, compliance['errors']

    operations = compliance['children'].select {|x| x['name'] == 'OPERATIONS'}.first
    assert_equal 1508, operations['passedIds'].count
    assert_equal 1508, operations['passed']
    assert_equal 16, operations['skippedIds'].count
    assert_equal 16, operations['skipped']
    assert_equal 371, operations['failedIds'].count
    assert_equal 371, operations['failed']

  end

end
