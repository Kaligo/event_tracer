require_relative '../event_tracer'
require_relative './basic_decorator'
# NOTES
# Datadog interface to send our usual actions
# BasicDecorator adds a transparent interface on top of the datadog interface
#
# Usage: EventTracer.register :datadog,
#          EventTracer::DataDogLogger.new(DataDog, allowed_tags: ['tag_1', 'tag_2'])
#
#        data_dog_logger.info metrics: [:counter_1, :counter_2]
#        data_dog_logger.info metrics: { counter_1: { type: :counter, value: 1}, gauce_2: { type: :gauce, value: 10 } }

module EventTracer
  class DatadogLogger < BasicDecorator

    SUPPORTED_METRIC_TYPES = {
      counter: :count,
      distribution: :distribution,
      gauge: :gauge,
      set: :set,
      histogram: :histogram
    }
    DEFAULT_METRIC_TYPE = :count
    DEFAULT_COUNTER = 1

    def initialize(decoratee, allowed_tags: [])
      super(decoratee)
      @allowed_tags = allowed_tags
    end

    LOG_TYPES.each do |log_type|
      define_method log_type do |**args|
        metrics = args[:metrics]

        return fail_result('Invalid Datadog config') unless valid_args?(metrics)
        return success_result if metrics.empty?

        tags = build_tags(args)

        send_metrice(metrics, tags)

        success_result
      end
    end

    private

    attr_reader :decoratee, :allowed_tags
    alias_method :datadog, :decoratee

    def send_metrice(metrice, tags)
      case metrice
      when String, Symbol
        datadog.public_send(DEFAULT_METRIC_TYPE, metrice, DEFAULT_COUNTER, tags: tags)
      when Array
        metrice.each do |metric|
          send_metrice(metric, tags)
        end
      when Hash
        metrice.each do |metric_name, metric_payload|
          metric_type = SUPPORTED_METRIC_TYPES[metric_payload.fetch(:type).to_sym]
          datadog.public_send(metric_type, metric_name, metric_payload.fetch(:value), tags: tags) if metric_type
        end
      end
    end

    def valid_args?(metrics)
      metrics && (metrics.is_a?(Hash) || metrics.is_a?(Array))
    end

    def build_tags(args)
      args.slice(*allowed_tags).map do |tag, value|
        "#{tag}:#{value}"
      end
    end
  end
end
