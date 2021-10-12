# frozen_string_literal: true

require 'time'
require_relative 'dynamo_db_client'
require_relative 'dynamo_db_log_worker'
require_relative 'dynamo_db_default_processor'

module EventTracer
  class DynamoDBLogger
    def initialize(buffer: Buffer.new(buffer_size: 0), log_processor: EventTracer::DynamoDBDefaultProcessor.new)
      @buffer = buffer
      @log_processor = log_processor
    end

    EventTracer::LOG_TYPES.each do |log_type|
      define_method log_type do |**args|
        save_message log_type, **args
      end
    end

    private

      attr_reader :buffer, :log_processor

      def save_message(log_type, action:, message:, **args)
        payload = log_processor.call(log_type, action: action, message: message, args: args)

        unless buffer.add(payload)
          all_payloads = buffer.flush + [payload]
          DynamoDBLogWorker.perform_async(all_payloads)
        end

        LogResult.new(true)
      end

  end
end
