class RunTestsJob < ActiveJob::Base
  queue_as :default

  def perform(testrun_id)

    Rails.logger.debug "#{self.class.name}: I'm performing my job #{testrun_id}"
    testrun = TestRun.find(testrun_id)
    testrun.execute()
    Rails.logger.debug "finished job"

  end
end
