class RunTestsJob < ActiveJob::Base
  queue_as :default

  def perform(testrun_id)

    Rails.logger.debug "#{self.class.name}: Starting Test Run #{testrun_id}"
    testrun = TestRun.find(testrun_id)
    testrun.execute()
    Rails.logger.debug "#{self.class.name}: Finished Test Run #{testrun_id}"

  end
end
