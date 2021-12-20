# frozen_string_literal: true

require 'time'
require_relative 'client'
require_relative 'worker'
require_relative 'default_processor'

module EventTracer
  module DynamoDB
    class Logger < BufferedLogger
      def initialize(buffer: Buffer.new(buffer_size: 0), log_processor: DefaultProcessor.new)
        super(buffer: buffer, log_processor: log_processor, worker: Worker)
      end
    end
  end
end
