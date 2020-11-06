require_relative '../event_tracer'
require_relative './basic_decorator'
# NOTES
# Datadog interface to send our usual actions
# BasicDecorator adds a transparent interface on top of the datadog interface
#
# Usage: EventTracer.register :datadog, EventTracer::DataDogLogger.new(DataDog)
#        data_dog_logger.info datadog: { increment: { counter_1: 1, counter_2: 2 }, set: { gauge_1: 1 } }
#        data_dog_logger.info datadog: { increment: { counter_1: { value: 1, tags: ['tag1, tag2']} } }

module EventTracer
  class DatadogLogger < BasicDecorator

    class InvalidTagError < StandardError; end

    SUPPORTED_METRICS ||= %i[increment set distribution gauge histogram].freeze

    LOG_TYPES.each do |log_type|
      define_method log_type do |**args|
        return LogResult.new(false, 'Invalid datadog config') unless args[:datadog]&.is_a?(Hash)

        applied_metrics(args[:datadog]).each do |metric|
          metric_args = args[:datadog][metric]
          return LogResult.new(false, "Datadog metric #{metric} invalid") unless metric_args.is_a?(Hash)

          send_metric metric, metric_args
        rescue InvalidTagError => e
          return LogResult.new(false, e.message)
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
      payload.each do |increment, attribute|
        if attribute.is_a?(Hash)
          begin
            datadog.send(
              format_metric(metric),
              increment,
              attribute.fetch(:value),
              format_tags(attribute.fetch(:tags))
            )
          rescue KeyError
            raise InvalidTagError, "Datadog payload { #{increment}: #{attribute} } invalid"
          end
        else
          datadog.send(format_metric(metric), increment, attribute)
        end
      end
    end

    def format_tags(tags)
      return tags if tags.is_a?(Array)

      tags.inject([]) do |acc, (tag, value)|
        acc << "#{tag}|#{value}"
      end
    end

    def format_metric(metric)
      metric == :increment ? :count : metric
    end
  end
end
