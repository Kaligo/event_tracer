# frozen_string_literal: true

require 'time'

module EventTracer
  class BufferedLogger
    def initialize(log_processor:, worker:, buffer: Buffer.new(buffer_size: 0))
      @buffer = buffer
      @worker = worker
      @log_processor = log_processor
    end

    EventTracer::LOG_TYPES.each do |log_type|
      define_method log_type do |**args|
        save_message log_type, **args
      end
    end

    private

    attr_reader :buffer, :log_processor, :worker

    def save_message(log_type, action:, message:, **args)
      payload = log_processor.call(log_type, action: action, message: message, args: args)

      unless buffer.add(payload)
        all_payloads = buffer.flush + [payload]
        execute_payload(all_payloads)
      end

      LogResult.new(true)
    end

    def execute_payload(payloads)
      worker.perform_async(payloads)
    rescue JSON::GeneratorError => e
      filtered_payloads = filter_invalid_data(payloads)

      EventTracer.warn(
        loggers: %i(base),
        action: self.class.name,
        app: EventTracer::Config.config.app_name,
        error: e.class.name,
        message: e.message,
        payload: payloads - filtered_payloads
      )

      worker.perform_async(filtered_payloads) if filtered_payloads.any?
    end

    def filter_invalid_data(payloads)
      payloads.select { |payload| payload.to_json rescue false }
    end
  end
end
