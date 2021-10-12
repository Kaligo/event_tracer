module EventTracer
  class DynamoDBDefaultProcessor
    def call(log_type, action:, message:, args:)
      args.merge(
        timestamp: Time.now.utc.iso8601(6),
        action: action,
        message: message,
        log_type: log_type,
        app: EventTracer::Config.config.app_name
      )
    end
  end
end
