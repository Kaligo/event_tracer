require 'bundler/setup'
require 'event_tracer'
require 'data_helpers/mock_logger'
require 'data_helpers/mock_appsignal'
require 'data_helpers/mock_datadog'

DynamoDBConfig.config.app_name = 'test_app'
DynamoDBConfig.config.table_name = 'test_table'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
