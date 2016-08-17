TemplateService::Application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.serve_static_files = false
  config.force_ssl = true
  config.log_level = :debug

  if ENV['MEMCACHED_CONFIGURATION']
    elasticache = Dalli::ElastiCache.new(ENV['MEMCACHED_CONFIGURATION'])
    server_config = {
      namespace: 'template-service',
      failover: true,
      socket_timeout: 1.5,
      socket_failure_delay: 0.2,
      compress: true
    }
    config.cache_store = :dalli_store, elasticache.servers, server_config
  end

  if ENV['PAPERTRAIL_HOST']
    config.logger = RemoteSyslogLogger.new(
      ENV['PAPERTRAIL_HOST'],
      ENV['PAPERTRAIL_PORT'],
      local_hostname: ENV['NEW_RELIC_APP_NAME'],
      program: "#{defined?(Sidekiq::CLI) ? 'sidekiq' : 'rails'}##{Socket.gethostname}"
    )
    config.logger.formatter = LogFormatter.new
  else
    config.logger = Logger.new(STDOUT)
  end

  config.mongoid.logger = config.logger
  Sidekiq::Logging.logger = config.logger
  Mongoid.logger.level = Logger::INFO
  Mongo::Logger.logger = config.logger

  config.i18n.fallbacks = true

  config.active_support.deprecation = :notify
end
