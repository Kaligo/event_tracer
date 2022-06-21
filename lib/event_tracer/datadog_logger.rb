require_relative './metric_logger'

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
  class DatadogLogger < MetricLogger

    SUPPORTED_METRIC_TYPES = {
      counter: :count,
      distribution: :distribution,
      gauge: :gauge,
      set: :set,
      histogram: :histogram
    }.freeze
    DEFAULT_METRIC_TYPE = :count
    DEFAULT_COUNTER = 1

    def initialize(decoratee, allowed_tags: [], default_tags: {})
      super(decoratee)
      @allowed_tags = allowed_tags.freeze
      @default_tags = default_tags.freeze
    end

    private

    def send_metric(metric_type, metric_name, value, tags)
      datadog.public_send(metric_type, metric_name, value, tags: tags)
    end

    alias_method :datadog, :decoratee

    def build_tags(args)
      default_tags.merge(args.slice(*allowed_tags)).map do |tag, value|
        "#{tag}:#{value}"
      end
    end
  end
end
