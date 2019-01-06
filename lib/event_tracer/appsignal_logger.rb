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
        SUPPORTED_METRICS.each do |metric|
          next unless args[:appsignal] && args[:appsignal][metric].is_a?(Hash)
          send_metric(metric, args[:appsignal][metric]) unless args[:appsignal][metric].empty?
        end
        true
      end
    end

    private

      attr_reader :appsignal, :decoratee
      alias_method :appsignal, :decoratee

      def send_metric(metric, payload)
        payload.each do |increment, value|
          appsignal.send(metric, increment, value)
        end
      end

  end
end
