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

    servers = Server.all.select {|s| (s.tags & excluded_tags).empty? and Rails.application.config.fhir_sequence == s.fhir_sequence and !s.hidden}.sort {|l,r| (r.percent_passing||0) <=> (l.percent_passing||0)}

    servers.each_with_index do |s, i|

      if TestRun.where(:server => s, :status.in => ['pending', 'running']).length == 0

        tests = Test.where({multiserver: false}).sort {|l,r| l.name <=> r.name}
        tests.select! { |t| s.supported_suites.include? t.id }

        if tests.length > 0
          test_run = TestRun.new({server: s, date: Time.now, nightly: true, supported_only: true})
          test_run.add_tests(tests)
          test_run.save!
          RunTestsJob.perform_later(test_run.id.to_s)
          puts "\tStarted Testing Server #{i+1} of #{servers.length}"
        else
          puts "\tNo supported test suites for server #{s.id}"
        end
      else
        puts "\tServer #{i+1} of #{servers.length} is already under test"
      end

    end

  end

  desc "identify stalled tasks and rerun"
  task :restart_stalled_runs => [:environment] do

    TestRun.where(:status=> 'running', :last_updated.lte => 10.minutes.ago).each do |test_run|

      test_run.status = 'stalled'
      test_run.save

      RunTestsJob.perform_later(test_run.id.to_s)
      
    end

  end

  desc "back fill blank names"
  task :guess_server_names => [:environment] do
    Server.all.select {|s| s.name.blank?}.each {|s| s.guess_name}
  end

  desc "remove duplicate servers"
  task :remove_duplicate_servers, [:delete] => :environment do |t, args|
    servers = Server.all
    servers_by_url = {}

    servers.each do |server|
      url = Addressable::URI.parse(server.url).normalize.to_s
      url = url.chop if url[-1] == '/'
      servers_by_url[url] ||= []
      servers_by_url[url] << server
    end

    servers_by_url.values.each do |list|
      next if list.length <= 1
      list.sort! do |l,r|
        if (l.name_guessed != r.name_guessed)
          (l.name_guessed ? 0 : 1) <=> (r.name_guessed ? 0 : 1)
        else
          (l.summary.try(:generated_at)||Time.new(0)) <=> (r.summary.try(:generated_at)||Time.new(0))
        end
      end
      keep = list.pop
      puts "Keeping 1 of #{list.length+1}: #{keep.name} => #{keep.url}"
      list.each do |server|
        puts "\tDeleting: #{server.name} => #{server.url}"
        server.delete() if args.delete
      end
    end

  end

  desc "cleanup bad servers"
  task :servers_cleanup, [:delete] => :environment do |t, args|
    print 'checking'
    bad = Server.all.select do |s|
      print '.'
      $stdout.flush
      s.summary.nil? && s.name_guessed && s.client_id.nil? && s.tags.blank? && !s.available?
    end
    bad.each do |server|
      puts "Deleting: #{server.name}: #{server.url}"
      server.delete() if args.delete
    end
  end

  desc "cleanup orphaned test runs"
  task :test_runs_cleanup, [:age] => :environment do |t, args|
    age = args.age.nil? ? (Time.now - 1.day).to_s : DateTime.parse(args.age).to_s
    TestRun.where(:date.lte => age, :status.in => ["pending", "running"]).update_all(status: 'cancelled')
  end

  desc "upgrade db to store generated_at from summary at the server level"
  task :copy_generated_at_to_server => [:environment] do

    Server.each do |server|
      server.last_run_at = server.summary.generated_at unless server.summary.nil?
      server.save
    end

  end

  desc "Update servers with version information stored in their conformance statement"
  task :update_version_information => [:environment] do 
    Server.each do |server|
      # server.load_conformance
      server.extract_version_from_conformance
      print "#{server.name} (#{server.url}): #{server.fhir_sequence} | #{server.fhir_version}\n"

    end
  end

  desc "List any duplicate urls in the system"
  task :list_duplicate_urls => [:environment] do 
    duplicate_urls = Server.all.group_by{ |e| e.url}.select {|k, v| v.size > 1}.map(&:first).sort

    duplicate_urls.each do |url|
      servers = Server.where(url: url).order_by("last_run_at" => "$desc")
      print "\n---\t #{url}\n"
      servers.each do |server|
        last_run_days_ago = 999
        last_run_days_ago = (Date.today - server.last_run_at.to_date).to_i unless server.last_run_at.nil?
        test_runs = TestRun.where(server_id: server._id, status: "finished").order_by("date" => "asc")
        first_run_days_ago = 999
        first_run_days_ago = (Date.today - test_runs.first.date).to_i if test_runs.first
        print "\t #{server._id} hid: #{server.hidden}\t #{test_runs.count} runs \t first #{first_run_days_ago}\tlast #{last_run_days_ago} days ago\n"
      end
    end

  end

  desc "Set hidden flag on server [server_id,hidden=true])"
  task :set_server_hidden_flag, [:server_id, :hidden] => :environment do |t, args|

    hidden = args.hidden.nil? ? true : args.hidden.to_s.downcase == 'true'

    server = Server.find(args.server_id)
    server.hidden = hidden
    server.save
  end

  desc "Calculate the total number of tests run using the system"
  task :calculate_total_tests => [:environment] do
    tests = 0
    TestResult.each do | result |
      tests += result.result.length
      if tests.modulo(1000).zero?
        print '.'
        $stdout.flush
      end
    end
    Statistics.all.destroy
    stats = Statistics.new({tests_run: tests})
    stats.save
  end

  desc "Guesses nightly tag for tests runs from before tag was added correctly"
  task :flag_nightly => [:environment] do
    end_date = Date.new(2016, 11, 1)
    start_hour = 0
    end_hour = 9
    test_max = 5
    # Not doing this super efficiently, but querying specific datetimes is hard through Mongo
    TestRun.where({ :date.lte => end_date }).each do | run |
      if run.test_ids.length >= test_max and run.date.hour < end_hour and run.date.hour >= start_hour
        run.nightly = true
        run.save
      end
    end
  end

  desc "Adds badges to the database"
  task :add_badges => [:environment] do
    Badge.all.destroy
    # Dummy (Always Pass)
    dummy_badge = Badge.new({
      id: "DUMMY",
      name: "Dummy",
      suites: [],
      tests: [],
      description: "This server exists",
      link: "www.google.com"
    })
    dummy_badge.save
    # Terminology
    term_badge = Badge.new({
      id: "TERM",
      name: "Terminology",
      suites: ["FAIL"],
      tests: [],
      description: "This server...",
      link: "https://www.hl7.org/fhir/terminology-service.html"
    })
    # Conformance Service
    # Knowledge Repository
    # Measure Processor

    # Security
    sec_badge = Badge.new({
      id: "SEC",
      name: "Security",
      suites: [],
      tests: ["CAEP1","CAEP3","CAEP5"],
      description: "This server...",
      link: ""
    })
    sec_badge.save
    # EHR (Read-Only)
    ehr_badge = Badge.new({
      id: "EHR",
      name: "Electronic Health Record",
      suites: ["readtest"],
      tests: [],
      description: "This server...",
      link: ""
    })
    ehr_badge.save
    # HIE
    Badge.new({
      id: "HIE",
      name: "Health Information Exchange",
      suites: ["FAIL"],
      tests: [],
      description: "This server...",
      link:""
    })
    # Claims
    claims_badge = Badge.new({
      id: "CLAIM",
      name: "Claims",
      suites: [
        "connectathonfinancialtracktest",
        "resourcetest_account",
        "resourcetest_chargeitem",
        "resourcetest_claim",
        "resourcetest_claimresponse",
        "resourcetest_contract",
        "resourcetest_coverage",
        "resourcetest_eligibilityrequest",
        "resourcetest_eligibilityresponse",
        "resourcetest_enrollmentrequest",
        "resourcetest_enrollmentresponse",
        "resourcetest_explanationofbenefit",
        "resourcetest_paymentnotice",
        "resourcetest_paymentreconciliation",
        "searchtest_account",
        "searchtest_chargeitem",
        "searchtest_claim",
        "searchtest_claimresponse",
        "searchtest_contract",
        "searchtest_coverage",
        "searchtest_eligibilityrequest",
        "searchtest_eligibilityresponse",
        "searchtest_enrollmentrequest",
        "searchtest_enrollmentresponse",
        "searchtest_explanationofbenefit",
        "searchtest_paymentnotice",
        "searchtest_paymentreconciliation"
      ],
      tests: [],
      description: "This server...",
      link: ""
    })
    claims_badge.save
    # Updates badges for all servers
    Server.all.each do |server|
      server.check_badges
    end

  end

end
