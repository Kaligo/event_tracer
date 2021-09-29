require 'bundler/setup'
require 'event_tracer'
require 'data_helpers/mock_logger'
require 'data_helpers/mock_appsignal'
require 'data_helpers/mock_datadog'

EventTracer::APP_NAME = 'test_app'
EventTracer::DYNAMO_DB_TABLE_NAME = 'test_table'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
