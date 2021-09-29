# This is a mock aws-sdk-dynamodb module for testing purposes.

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
