# sudo god -c /var/app/current/foreman.god -D

sysenv_dirs = %w(/opt/elasticbeanstalk/containerfiles /opt/elasticbeanstalk/support)
sysenv_files = sysenv_dirs.map { |d| "#{d}/envvars" } + sysenv_dirs.map { |d| "#{d}/envvars.d/sysenv" }
support_dirs = %w(/var/app/containerfiles /var/app/support)

env_file = sysenv_files.detect { |f| File.exist? f }
support_dir = support_dirs.detect { |d| Dir.exist? d }

APPENV = IO.readlines(env_file).each_with_object({}) do |l, hsh|
  res = l.match(/^export\s+(\S+)="(\S+)"/)
  hsh[res[1]] = res[2] if res
end
APPENV['PATH'] = %w(
  /opt/rubies/ruby-current/bin
  /usr/local/bin
  /bin
  /usr/bin
  /usr/local/sbin
  /usr/sbin
  /sbin
  /opt/aws/bin
  /home/ec2-user/bin).join(':')

God.terminate_timeout = 60.seconds
God.pid_file_directory ||= "#{support_dir}/pids"

# email integration
God::Contacts::Email.defaults do |d|
  d.from_email = 'server-alerts+god@johnio.com'
  d.from_name = "[Foreman God] #{APPENV['NEW_RELIC_APP_NAME']}"
  d.delivery_method = :sendmail
end

God.contact(:email) do |c|
  c.name = 'server-alerts'
  c.group = 'alerts'
  c.to_email = 'server-alerts@johnio.com'
end

# slack integration
God::Contacts::Slack.defaults do |d|
  d.account = 'johnio'
  d.token = APPENV['RACK_ENV'] == 'production' ? 'slack_staging_token' : 'slock_production_token'
  d.format = "[%{category}]: %{priority} alert on %{host}: %{message} (%{time})"
end

God.contact(:slack) do |s|
  s.channel = APPENV['RACK_ENV'] == 'production' ? '#eng-server-god' : '#eng-server-god-stage'
  s.name = 'slack-god-room'
  s.group = 'alerts'
end

IO.readlines(File.expand_path("../Procfile", __FILE__)).each do |raw_line|
  line = raw_line.chomp
  next if line.empty?
  next if line.start_with?('#')
  res = line.match(/^(\w+):(.+)/)
  next unless res
  name = res[1]
  command = res[2].strip
  # a hack to get memory max
  memory_setting = command.match(/MAX_MEM=(\d+)/)
  memory_max = memory_setting[1].to_i if memory_setting
  God.watch do |w|
    w.name = name
    w.dir = "/var/app/current"
    w.start = "#{command}"

    w.log = "#{support_dir}/logs/#{name}_bg_job.log"
    w.env = APPENV

    w.start_grace = 5.seconds
    w.restart_grace = 10.seconds
    w.stop_timeout = 30.seconds
    w.behavior(:clean_pid_file) # it cleans up pid file on start, not after the proc dies

    memory_max_setting = (memory_max || APPENV['GOD_MEMORY_MAX'] || 500).to_i
    w.keepalive(memory_max: memory_max_setting.megabytes)

    # Need root access for event system monitoring / setuid / setgid
    w.uid = 'webapp'
    w.gid = 'webapp'

    w.transition(:up, :start) do |on|
      on.condition(:process_exits) do |c|
        c.notify = { contacts: %w(alerts), category: APPENV['NEW_RELIC_APP_NAME'] }
      end
    end

    w.start_if do |start|
      start.condition(:process_running) do |c|
        c.interval = 30.seconds
        c.running = false
      end
    end

    w.lifecycle do |on|
      on.condition(:flapping) do |c|
        c.to_state = [:start, :restart]
        c.transition = :unmonitored
        c.times = 5
        c.within = 5.minutes
        c.retry_in = 10.minutes
        c.retry_times = 5
        c.retry_within = 2.hour
      end
    end
  end
end
