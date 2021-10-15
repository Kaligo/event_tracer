module EventTracer
  module DynamoDB
    class Client
      def self.call
        Aws::DynamoDB::Client.new
      end
    end
  end
end
