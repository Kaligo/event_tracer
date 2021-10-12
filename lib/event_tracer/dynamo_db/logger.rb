# frozen_string_literal: true

require 'time'
require_relative 'client'
require_relative 'worker'
require_relative 'default_processor'

module EventTracer
  module DynamoDB
    class Logger
      def initialize(buffer: Buffer.new(buffer_size: 0), log_processor: DefaultProcessor.new)
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
            Worker.perform_async(all_payloads)
          end

          LogResult.new(true)
        end

    end
  end
end
