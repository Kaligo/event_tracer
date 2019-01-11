require_relative '../event_tracer'
require_relative './basic_decorator'

# NOTES
# Appsignal interface to send our usual actions 
# BasicDecorator adds a transparent interface on top of the appsignal interface
#
# Usage: EventTracer.register :appsignal, EventTracer::AppsignalLogger.new(Appsignal)
#        appsignal_logger.info appsignal: { increment_counter: { counter_1: 1, counter_2: 2 }, set_gauge: { gauge_1: 1 } }
module EventTracer
  class AppsignalLogger < BasicDecorator

    SUPPORTED_METRICS ||= %i(increment_counter add_distribution_value set_gauge)

    LOG_TYPES.each do |log_type|
      define_method log_type do |**args|
        return LogResult.new(false, "Invalid appsignal config") unless args[:appsignal] && args[:appsignal].is_a?(Hash)

        applied_metrics(args[:appsignal]).each do |metric|
          metric_args = args[:appsignal][metric]
          return LogResult.new(false, "Appsignal metric #{metric} invalid") unless metric_args && metric_args.is_a?(Hash) 

          send_metric metric, metric_args
        end

        LogResult.new(true)
      end
    end

    private

      attr_reader :appsignal, :decoratee
      alias_method :appsignal, :decoratee

      def applied_metrics(appsignal_args)
        appsignal_args.keys.select { |metric| SUPPORTED_METRICS.include?(metric) }
      end

      def send_metric(metric, payload)
        payload.each do |increment, value|
          appsignal.send(metric, increment, value)
        end
      end

  end
end
