# run with: god -c /path/to/config.god [add -D if you want to not-deamonize god] 
# This is the actual config file used to keep the delayed_job running 

APPLICATION_ROOT = "/home/crucible/crucible-beta"
RAILS_ENV = "production"
WORKER_COUNT = 3
SERVER="beta"

(0...WORKER_COUNT).each do |i|
  God.watch do |w| 
    w.name = "delayed_job_#{SERVER}_#{i}"
    w.group = "delayed_job_#{SERVER}"
    w.interval = 15.seconds 
    w.start = "/bin/bash -c 'cd #{APPLICATION_ROOT}; /usr/bin/env RAILS_ENV=#{RAILS_ENV} #{APPLICATION_ROOT}/bin/delayed_job -i #{i} start >> /tmp/delayed_job_#{SERVER}.out'"
    w.stop = "/bin/bash -c 'cd #{APPLICATION_ROOT}; /usr/bin/env RAILS_ENV=#{RAILS_ENV} #{APPLICATION_ROOT}/bin/delayed_job -i #{i} stop'"
    w.log = "#{APPLICATION_ROOT}/log/god_delayed_job.log"
    w.start_grace = 30.seconds 
    w.restart_grace = 30.seconds 
    w.pid_file = "#{APPLICATION_ROOT}/tmp/pids/delayed_job.#{i}.pid"

    w.behavior(:clean_pid_file) 

    w.start_if do |start| 
      start.condition(:process_running) do |c| 
        c.interval = 5.seconds 
        c.running = false 
      end 
    end 

    w.restart_if do |restart| 
      restart.condition(:memory_usage) do |c| 
        c.above = 1200.megabytes 
        c.times = [3, 5] # 3 out of 5 intervals 
      end 

      restart.condition(:cpu_usage) do |c| 
        c.above = 98.percent 
        c.times = 5 
      end 
    end 

    # lifecycle 
    w.lifecycle do |on| 
      on.condition(:flapping) do |c| 
        c.to_state = [:start, :restart] 
        c.times = 5 
        c.within = 5.minute 
        c.transition = :unmonitored 
        c.retry_in = 10.minutes 
        c.retry_times = 5 
        c.retry_within = 2.hours 
      end 
    end 
  end
end

