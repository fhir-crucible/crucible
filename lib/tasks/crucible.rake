namespace :crucible do

  namespace :db do
    desc 'Reset DB; by default pulls from a local dump under the db directory.'
    task :reset, [:source] => :environment do |t, args|
      source = "_#{args.source}" if args.source
      dump_archive = File.join('db', "crucible_reset#{source}.tar.gz")
      dump_extract = File.join('tmp', 'crucible_reset')
      target_db = Mongoid.default_session.options[:database]
      puts "Resetting #{target_db} from #{dump_archive}"
      Mongoid.default_session.with(database: target_db) { |db| db.drop }
      system "tar xf #{dump_archive} -C tmp"
      system "mongorestore -d #{target_db} #{dump_extract}"
      FileUtils.rm_r dump_extract
    end
  end
  

  desc "Execute all tests against all servers"
  task :test_all => [:environment] do
    test_count = Test.count
    i = 0
    length = Server.all.count
    Server.all.each do |s|
      i+=1
      puts  "#{s.name}(#{s.url})"
      begin
        x = (RestClient::Request.execute(:method => :get, :url => s.url+'/metadata', :timeout => 30, :open_timeout => 30)).match /Conformance/
        unless x
          puts "#{s.name}(#{s.url}) skipped for bad return"
          next
        end
      rescue
        puts  "#{s.name}(#{s.url}) skipped for error"
        next
      end
      puts  "#{s.name}(#{s.url}) - GOT CONFORMANCE"
      progressbar = ProgressBar.create(:total => test_count)
      test_run = TestRun.new
      test_run.server = s
      test_run.save

      client1 = FHIR::Client.new(s.url)
      # client2 = FHIR::Client.new(result.test_run.destination_server.url) if result.test_run.is_multiserver
      # TODO: figure out multi server
      client2 = nil
      executor = Crucible::Tests::Executor.new(client1, client2)

      Test.where({multiserver: false}).sort {|l,r| l.name <=> r.name}.each do |t|
        begin
          puts  "\t #{i}/#{length}: #{s.name}(#{s.url})"

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

        rescue Exception => e
          puts  "Error on #{t.title} against #{s.url}!"
          e.backtrace
        end
      end
      Aggregate.update(s, test_run)
      compliance = Aggregate.get_compliance(s)
      summary = Summary.new({server_id: s.id, test_run: test_run, compliance: compliance, generated_at: Time.now})
      s.summary = summary
      s.percent_passing = (compliance['passed'].to_f / ([compliance['total'].to_f || 0, 1].max)) * 100.0
      summary.save!

      s.save!
    end
  end

end
