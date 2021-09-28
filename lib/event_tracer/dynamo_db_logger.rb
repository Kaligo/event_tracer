# frozen_string_literal: true

require 'time'

module EventTracer
  class DynamoDBLogger
    def initialize(buffer = nil)
      @buffer = buffer
    end

    EventTracer::LOG_TYPES.each do |log_type|
      define_method log_type do |**args|
        save_message log_type, **args
      end
    end

    private

      attr_reader :buffer

      def save_message(log_type, action:, message:, **args)
        payload = prepare_payload(log_type, action: action, message: message, args: args)

        if buffer
          unless buffer.add(payload)
            all_payloads = buffer.flush + [payload]
            DynamoDBLogWorker.perform_async(all_payloads)
          end
        else
          DynamoDBLogWorker.perform_async(payload)
        end

        LogResult.new(true)
      end

      def prepare_payload(log_type, action:, message:, args:)
        args.merge(
          timestamp: Time.now.utc.iso8601(6),
          action: action,
          message: message,
          log_type: log_type,
          app: EventTracer::APP_NAME
        )
      end

  end
end
