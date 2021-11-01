require 'dry-configurable'

module EventTracer
  class Config
    extend Dry::Configurable

    setting :app_name, default: 'app_name'

    # TODO: switch to namespace in v1.0
    setting :dynamo_db_table_name, default: 'logs'
    setting :dynamo_db_client
  end
end
