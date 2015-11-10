class RunTestsJob < ActiveJob::Base
  queue_as :default

  def perform(test_run_id)

    Rails.logger.debug "#{self.class.name}: Starting Test Run #{test_run_id}"
    testrun = TestRun.find(test_run_id)
    testrun.execute()
    Rails.logger.debug "#{self.class.name}: Finished Test Run #{test_run_id}"

  end
end
