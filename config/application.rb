require File.expand_path('../boot', __FILE__)

require "action_controller/railtie"
require "action_mailer/railtie"

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module TemplateService
  class Application < Rails::Application
    require "#{config.root}/lib/log_formatter"

    # Eager load directories to avoid thread-safety issues with autoloading
    config.eager_load = true
    config.eager_load_paths += %W(#{config.root}/lib #{config.root}/app/workers)

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :current_password, :password_confirmation]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    config.cache_store = :dalli_store

    # Configure generators
    config.generators do |g|
      g.assets false
      g.helper false
      g.orm :mongoid
      g.test_framework :rspec
    end

    config.i18n.fallbacks = true
    config.available_locales = [:ar, :de, :en, :es, :fr, :it, :ja, :ko, :nl, :'pt-br', :ru, :th, :tr, :zh, :'zh-tw']

    config.cache_store = :dalli_store

    config.log_formatter = LogFormatter.new

    config.template_page_size = 50
  end
end
