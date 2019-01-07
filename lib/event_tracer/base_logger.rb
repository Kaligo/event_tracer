require_relative '../event_tracer'
require_relative './basic_decorator'
require 'json'

# Usage: EventTracer.register :base, EventTracer::BaseLogger.new(Logger.new(STDOUT))
module EventTracer
  class BaseLogger < BasicDecorator

    LOG_TYPES.each do |log_type|
      define_method log_type do |*args|
        send_message(log_type, *args)
      end
    end

    private

      attr_reader :logger, :decoratee
      alias_method :logger, :decoratee

      # execute only if there's a message to be logged
      def send_message(log_method, action: nil, simple_message: nil, **args)
        return false unless simple_message || args[:message]
        message_to_send = simple_message ? simple_message : args.to_json
        logger.send(log_method, "[#{action}] #{message_to_send}")
      end

  end
end
