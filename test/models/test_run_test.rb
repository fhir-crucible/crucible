require_relative '../test_helper'

class TestRunTest < ActiveSupport::TestCase

  def setup
    dump_database
    @conformance_xml = File.read(Rails.root.join('test','fixtures','xml','capability_statement', 'full_capability_statement.xml'))
  end

  def test_add_test

    server = Server.new ({url: 'www.example.com'})
    testrun = TestRun.new({server: server, fhir_version: 'stu3'})

    assert_equal 0, testrun.tests.length
    assert_equal "pending", testrun.status

    tests = Test.all().limit(3)

    #add a single test
    testrun.add_tests(tests[0])

    assert_equal 1, testrun.tests.length

    #add multiple test
    testrun.add_tests(tests[1..2])

    assert_equal 3, testrun.tests.length

  end

  def test_execute_success_r4

    server = Server.new ({url: 'www.example.com'})
    testrun = TestRun.new({server: server, fhir_version: 'r4'})

    stub_request(:any, /www\.example\.com\/.*/).to_return(status: 404)
    stub_request(:get, "www.example.com/metadata").to_return(body: @conformance_xml).times(1)

    testrun.add_tests(Test.all().limit(3))
    assert testrun.execute()

    assert_equal "finished", testrun.status

    assert_equal 3, testrun.test_results.length

    # assert_equal testrun.server.percent_passing, 0
    refute_nil  testrun.server.summary

    #don't allow it to be run again
    refute testrun.execute()

  end

  def test_execute_success_stu3

    server = Server.new ({url: 'www.example.com'})
    testrun = TestRun.new({server: server, fhir_version: 'stu3'})

    stub_request(:any, /www\.example\.com\/.*/).to_return(status: 404)
    stub_request(:get, "www.example.com/metadata").to_return(body: @conformance_xml).times(1)

    testrun.add_tests(Test.all().limit(3))
    assert testrun.execute()

    assert_equal "finished", testrun.status

    assert_equal 3, testrun.test_results.length

    # assert_equal testrun.server.percent_passing, 0
    refute_nil  testrun.server.summary

    #don't allow it to be run again
    refute testrun.execute()

  end


  def test_execute_unavailable

    server = Server.new ({url: 'www.example.com'})
    testrun = TestRun.new({server: server, fhir_version: 'r4'})

    stub_request(:any, /www\.example\.com\/.*/).to_return(status: 404)
    stub_request(:get, "www.example.com/metadata").to_return(status: 500)

    testrun.add_tests(Test.first())
    refute testrun.execute()

    assert_equal "unavailable", testrun.status

  end

  def test_execute_errors

    server = Server.new ({url: 'www.example.com'})
    testrun = TestRun.new({server: server, fhir_version: 'stu3'})

    stub_request(:any, /www\.example\.com\/.*/).to_timeout
    stub_request(:get, "www.example.com/metadata").to_return(body: @conformance_xml).times(1)

    # Just use resource tests because we know they won't pass
    testrun.add_tests(Test.all().select { |t| t.name.start_with?('ResourceTest')}[0..9])

    assert testrun.execute()

    assert_equal 'finished', testrun.status
    assert_equal 10, testrun.test_results.length

    testrun.test_results.each do |tr|
      #todo: figure out a better way to ensure that none of these skip because seems unpredicatable
      assert tr.result.all? { |t| ['error', 'skip', 'fail'].include?(t['status']) }, "Bad status in #{tr.test_id}"
    end


  end

end
