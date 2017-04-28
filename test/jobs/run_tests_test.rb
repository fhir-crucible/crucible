
require_relative '../test_helper'

class RunTestsJobTest < ActiveSupport::TestCase

  def setup
    dump_database
    @conformance_xml = File.read(Rails.root.join('test','fixtures','xml','capability_statement', 'full_capability_statement.xml'))
  end

  def test_perform

    server = Server.new ({url: 'www.example.com'})
    testrun = TestRun.new({server: server})

    server.save
    testrun.save

    stub_request(:any, /www\.example\.com\/.*/).to_return(status: 404)
    stub_request(:get, "www.example.com/metadata").to_return(body: @conformance_xml).times(1)

    testrun.add_tests(Test.all().limit(3))
    RunTestsJob.perform_later(testrun.id.to_s)

    testrun = TestRun.find(testrun.id)

    assert_equal "finished", testrun.status
    assert_equal 3, testrun.test_results.length

  end
end
