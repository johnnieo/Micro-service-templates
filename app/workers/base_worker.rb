class BaseWorker
  include Sidekiq::Worker
  include ActiveSupport::Benchmarkable

  sidekiq_options backtrace: true

  def logger
    Rails.logger
  end

  def perform(model, method, *args)
    klass = begin
      model.constantize
    rescue => e
      logger.error "[#{self.class}] error calling constantize on #{model}, message=#{e.message}"
    end

    wrap("#{method}, #{args.join(', ')}") do
      klass.send(method.to_sym, *args)
    end
  end

  def wrap(description, &_block)
    description = "[#{self.class}] (#{description})"

    benchmark(description, level: :debug) { yield }
  rescue => e
    logger.error "[#{self.class}] Error processing job: #{description}: #{e.inspect}\n"
    logger.debug e.backtrace[0, 2].join("\n")
    raise e
  end
end
