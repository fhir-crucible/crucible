class RunTestsJob < ActiveJob::Base
  queue_as :default

  def perform(test_run_id)

    Delayed::Worker.logger.info "#{self.class.name}: Starting Test Run #{test_run_id}"
    testrun = TestRun.find(test_run_id)
    Delayed::Worker.logger.info "Test Run #{test_run_id}: #{testrun.try(:server).try(:name)}: #{testrun.try(:server).try(:url)}" 
    begin
      testrun.execute()
    rescue => exception
      Delayed::Worker.logger.error exception
      testrun.status = 'error'
      testrun.save
    end
    Delayed::Worker.logger.info "#{self.class.name}: Finished Test Run #{test_run_id}"

  end
end
