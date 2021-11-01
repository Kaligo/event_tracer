module EventTracer
  module DynamoDB
    class Client
      class << self
        extend Gem::Deprecate

        def call
          Aws::DynamoDB::Client.new
        end
        deprecate :call, 'EventTracer::Config.config.dynamo_db_client', 2021, 12
      end
    end
  end
end
