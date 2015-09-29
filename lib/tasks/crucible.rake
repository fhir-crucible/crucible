namespace :crucible do
  desc "Execute all tests against all servers"
  task :test_all => [:environment] do
    test_count = Test.count
    Server.all.each do |s|
      puts  "#{s.name}(#{s.url})"
      progressbar = ProgressBar.create(:total => test_count)
      test_run = TestRun.new
      test_run.server = s
      test_run.save
      begin
        Test.all.each do |t|
          client1 = FHIR::Client.new(s.url)
          # client2 = FHIR::Client.new(result.test_run.destination_server.url) if result.test_run.is_multiserver
          # TODO: figure out multi server
          client2 = nil
          executor = Crucible::Tests::Executor.new(client1, client2)


          test = executor.find_test(t.title)
          val = nil
          if t.resource_class?
            val = test.execute(t.resource_class.constantize)[0]["#{t.title}_#{t.resource_class.split("::")[1]}"][:tests]
          else
            val = test.execute()[0][t.title][:tests]
          end
          result = TestResult.new
          result.test = t
          result.server = s
          result.has_run = true
          result.result = val
          test_run.test_results << result
          test_run.save
          progressbar.increment
        end
      rescue e
        puts  "Error on #{t.title} against #{s.url}!"
      end
      Aggregate.update(s, test_run)
      compliance = Aggregate.get_compliance(s)
      summary = Summary.new({server_id: s.id, test_run: test_run, compliance: compliance, generated_at: Time.now})
      s.summary = summary
      s.percent_passing = (compliance['passed'].to_f / ([compliance['total'].to_f || 0, 1].min)) * 100.0
      summary.save!

      s.save!
    end
  end
end
