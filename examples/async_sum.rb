#
# bundle exec ruby examples/async_sum.rb client
# bundle exec ruby examples/async_sum.rb server
#

require "tennis"
require "tennis/backend/redis"

logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG
redis_url = "redis://localhost:6379"

Tennis.configure do |config|
  config.backend = Tennis::Backend::Redis.new(logger: logger, url: redis_url)
  config.logger = logger
end

class Job
  include Tennis::Job

  def sum(*numbers)
    sleep 0.4
    total = numbers.inject(&:+)
    puts "Sum #{numbers} => #{total}"
  end

  def job_dump
    nil
  end

  def self.job_load(_)
    new
  end
end


if ARGV[0] == "server"
  require "tennis/launcher"

  # Start Tennis.
  launcher = Tennis::Launcher.new(concurrency: 2, job_classes: [Job])
  launcher.async.start

  begin
    sleep 5 while true
  rescue Interrupt
    puts "Stopping the server..."
  ensure
    launcher.async.stop
  end
else
  # Instanciate a job and add the sum to the job to do.
  numbers = (1..9).to_a
  10.times do
    Job.new.async.sum(*numbers.sample(3))
  end
end
