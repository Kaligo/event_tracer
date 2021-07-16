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
        tags = build_tags(args)

        case args[:metrics]
        when Array
          args[:metrics].each do |metric|
            appsignal.public_send(DEFAULT_METRIC_TYPE, metric, DEFAULT_COUNTER, tags: tags)
          end
        when Hash
          args[:metrics].each do |metric_name, metric_payload|
            metric_type = SUPPORTED_METRIC_TYPES[metric_payload[:type].to_sym]
            appsignal.public_send(metric_type, metric_name, metric_payload[:value], tags: tags)
          end
        else
          return LogResult.new(false, 'Invalid DataDog config')
        end

        LogResult.new(true)
      end
    end

    private

    attr_reader :decoratee, :allowed_tags
    alias_method :datadog, :decoratee

    def build_tags(args)
      args.slice(**allowed_tags).map do |tag, value|
        "#{tag}:#{value}"
      end
    end
  end
end
