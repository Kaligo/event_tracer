require 'dry-configurable'
require 'dry/configurable/version'

module EventTracer
  class Config
    extend Dry::Configurable

    if Dry::Configurable::VERSION >= "0.13"
      setting :app_name, default: 'app_name'

      # TODO: switch to namespace in v1.0
      setting :dynamo_db_table_name, default: 'logs'
      setting :dynamo_db_client
      setting :dynamo_db_queue_name, default: 'low'
      setting :error_handler, default: ->(_error, _payload) {}
    else
      setting :app_name, 'app_name'

      # TODO: switch to namespace in v1.0
      setting :dynamo_db_table_name, 'logs'
      setting :dynamo_db_client
      setting :dynamo_db_queue_name, 'low'
      setting :error_handler, ->(_error, _payload) {}
    end
  end
end
