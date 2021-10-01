require 'dry-configurable'

module EventTracer
  class Config
    extend Dry::Configurable

    setting :app_name, default: 'app_name'
    setting :dynamo_db_table_name, default: 'logs'
  end
end
