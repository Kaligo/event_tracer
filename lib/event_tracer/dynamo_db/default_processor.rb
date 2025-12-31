module EventTracer
  module DynamoDB
    class DefaultProcessor
      def call(log_type, action:, message:, args:)
        timestamp = Time.now.utc.iso8601(6)

        args.merge(
          'timestamp' => timestamp,
          'action' => action,
          'action_timestamp' => "#{action}##{timestamp}",
          'message' => message,
          'log_type' => log_type.to_s,
          'app' => EventTracer::Config.config.app_name
        )
      end
    end
  end
end
