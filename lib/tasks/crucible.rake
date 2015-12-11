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
      system "mongorestore -d #{target_db} --batchSize=1 #{dump_extract}"
      FileUtils.rm_r dump_extract
    end
  end
  

  desc "Execute all tests against all servers"
  task :test_all => [:environment] do

    Server.all.each_with_index do |s, i|
      puts "\tStarting Server #{i+1} of #{Server.all.length}"

      test_run = TestRun.new({server: s})
      test_run.add_tests(Test.where({multiserver: false}).sort {|l,r| l.name <=> r.name})
      test_run.execute() do |result, j, total|
        puts "\tCompleted test #{j+1} of #{total} on Server #{i+1} of #{Server.all.length}"
      end

      puts "\tCompleted Server #{i+1} of #{Server.all.length}"

    end
  end

  desc "schedule a job for all servers"
  task :nightly_run => [:environment] do

    # currently we exclude servers tagged argonaut from the nightly run
    excluded_tags = ['argonaut']

    Server.all.select {|s| (s.tags & excluded_tags).empty?}.sort {|l,r| (r.percent_passing||0) <=> (l.percent_passing||0)}.each_with_index do |s, i|
      puts "\tStarting Server #{i+1} of #{Server.all.length}"

      test_run = TestRun.new({server: s, date: Time.now})
      test_run.add_tests(Test.where({multiserver: false}).sort {|l,r| l.name <=> r.name})
      test_run.save!
      RunTestsJob.perform_later(test_run.id.to_s)

    end

  end

end
