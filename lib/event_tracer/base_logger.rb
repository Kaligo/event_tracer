require_relative '../event_tracer'
require_relative './basic_decorator'
require 'json'

# Usage: EventTracer.register :base, EventTracer::BaseLogger.new(Logger.new(STDOUT))
module EventTracer
  class BaseLogger < BasicDecorator

    LOG_TYPES.each do |log_type|
      define_method log_type do |*args|
        send_message(log_type, *args)
        LogResult.new(true)
      end
    end

    private

      attr_reader :logger, :decoratee
      alias_method :logger, :decoratee

      # EventTracer ensures action & message is always populated
      def send_message(log_method, action:, message:, **args)
        data = args.merge(action: action, message: message)
        logger.public_send(log_method, data)
      end

  end
end
