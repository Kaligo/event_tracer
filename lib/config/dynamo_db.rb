require 'dry-configurable'

class DynamoDBConfig
  extend Dry::Configurable

  setting :app_name, default: 'app_name'
  setting :table_name, default: 'logs'
end
