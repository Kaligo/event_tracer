module EventTracer
  module DynamoDB
    class DefaultProcessor
      def call(log_type, action:, message:, args:)
        args.merge(
          'timestamp' => Time.now.utc.iso8601(6),
          'action' => action,
          'message' => message,
          'log_type' => log_type.to_s,
          'app' => EventTracer::Config.config.app_name
        )
      end
    end
  end
end
