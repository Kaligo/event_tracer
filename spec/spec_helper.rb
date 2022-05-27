require 'bundler/setup'
require 'event_tracer'
require 'data_helpers/mock_logger'
require 'data_helpers/mock_appsignal'
require 'data_helpers/mock_datadog'
require 'event_tracer/dynamo_db/logger'
require 'dry/configurable/test_interface'
require 'prometheus/client'

EventTracer::Config.enable_test_interface

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.order = :random
end
