require_relative '../event_tracer'
require_relative './basic_decorator'
# NOTES
# Datadog interface to send our usual actions
# BasicDecorator adds a transparent interface on top of the datadog interface
#
# Usage: EventTracer.register :datadog, EventTracer::DataDogLogger.new(DataDog)
#        data_dog_logger.info datadog: { increment: { counter_1: 1, counter_2: 2 }, set: { gauge_1: 1 } }

module EventTracer
  class DatadogLogger < BasicDecorator

    SUPPORTED_METRICS ||= %i[increment set distribution gauge histogram].freeze

    LOG_TYPES.each do |log_type|
      define_method log_type do |**args|
        return LogResult.new(false, 'Invalid datadog config') unless args[:datadog]&.is_a?(Hash)

        applied_metrics(args[:datadog]).each do |metric|
          metric_args = args[:datadog][metric]
          return LogResult.new(false, "Datadog metric #{metric} invalid") unless metric_args&.is_a?(Hash)

          send_metric metric, metric_args
        end

        LogResult.new(true)
      end
    end

    private

    attr_reader :datadog, :decoratee
    alias_method :datadog, :decoratee

    def applied_metrics(datadog_args)
      datadog_args.keys.select { |metric| SUPPORTED_METRICS.include?(metric) }
    end

    def send_metric(metric, payload)

      payload.each do |increment, value|
        puts "payload contains: increment: #{increment} value: #{value}"
        datadog.send(metric, increment, value)
      end
    end

  end
end
