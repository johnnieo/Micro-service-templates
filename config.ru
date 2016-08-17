# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)

use Rack::Status
use Rack::Deflater
use Rack::HealthCheck
run TemplateService::Application
