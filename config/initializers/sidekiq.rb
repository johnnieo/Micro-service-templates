Sidekiq::Client.reliable_push! unless Rails.env.test?

sidekiq_redis = {
  SIDEKIQ_TEMPLATES_REDIS: 'sidekiq-template-service'
}

sidekiq_redis.each do |sidekiq_name, service_name|
  connection_pool = ConnectionPool.new(size: Sidekiq.options[:concurrency] + 2) do
    # Need to change to different redis setup based on Rails env
    redis_config = { url: "redis://:p4ssw0rd@10.0.1.1:6380/15" }
    Redis.new(redis_config)
  end

  Kernel.const_set(sidekiq_name, connection_pool)
end

# change the default redis to match line 4
Sidekiq.configure_client do |config|
  config.redis = SIDEKIQ_TEMPLATES_REDIS
end

Sidekiq.configure_server do |config|
  Sidekiq::Client.reliable_fetch! if ENV['SIDEKIQ_RELIABLE_FETCH']

  # config.poll_interval = 15
  config.redis = SIDEKIQ_TEMPLATES_REDIS
end

# Disable Sidekiq logging
Sidekiq::Logging.logger = nil
