class RunTestsJob < ActiveJob::Base
  queue_as :default

  def perform(testrun_id, test_ids)

    Rails.logger.debug "#{self.class.name}: I'm performing my job #{testrun_id}"

    testrun = TestRun.find(testrun_id)
    tests = test_ids.map {|t| Test.find(t) }

    testrun.execute(tests)
    testrun.finish()

    Rails.logger.debug "finished job"

  end
end
