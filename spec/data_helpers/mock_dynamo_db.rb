# This is a mock DynamoDBClient for testing purposes.

class DynamoDBClient; end

module Aws
  module DynamoDB
    module Errors
      class ServiceError < StandardError
        attr_reader :message

        def initialize(_subject, error_message)
          @message = error_message
        end
      end
    end
  end
end
