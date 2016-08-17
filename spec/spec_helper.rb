require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'factory_girl_rails'

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.order = :random
end

def encrypt_param(value)
  Base64.urlsafe_encode64(Encryptor.encrypt(value.to_s, key: '1234abcd'))
end
