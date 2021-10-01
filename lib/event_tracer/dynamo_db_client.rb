module EventTracer
  class DynamoDBClient
    def self.call
      Aws::DynamoDB::Client.new
    end
  end
end
