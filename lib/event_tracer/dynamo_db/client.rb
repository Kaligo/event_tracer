# TODO: move this into logger class in v1.0
module EventTracer
  module DynamoDB
    class Client
      def self.call
        EventTracer::Config.dynamo_db_client || Aws::DynamoDB::Client.new
      end
    end
  end
end
