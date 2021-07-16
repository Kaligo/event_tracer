require_relative '../event_tracer'
require_relative './basic_decorator'

# NOTES
# Appsignal interface to send our usual actions
# BasicDecorator adds a transparent interface on top of the appsignal interface
#
# Usage: EventTracer.register :appsignal,
#          EventTracer::AppsignalLogger.new(Appsignal, allowed_tags: ['tag_1', 'tag_2'])
#
#        appsignal_logger.info metrics: [:counter_1, :counter_2]
#        appsignal_logger.info metrics: { counter_1: { type: :counter, value: 1 }, gauce_2: { type: :gauce, value: 10 } }
module EventTracer
  class AppsignalLogger < BasicDecorator

    SUPPORTED_METRIC_TYPES = {
      counter: :increment_counter,
      distribution: :add_distribution_value,
      gauge: :set_gauge
    }
    DEFAULT_METRIC_TYPE = :increment_counter
    DEFAULT_COUNTER = 1

    def initialize(decoratee, allowed_tags: [])
      super(decoratee)
      @allowed_tags = allowed_tags
    end

    LOG_TYPES.each do |log_type|
      define_method log_type do |**args|
        tags = args.slice(**allowed_tags)

        case args[:metrics]
        when Array
          args[:metrics].each do |metric|
            appsignal.public_send(DEFAULT_METRIC_TYPE, metric, DEFAULT_COUNTER, tags)
          end
        when Hash
          args[:metrics].each do |metric_name, metric_payload|
            metric_type = SUPPORTED_METRIC_TYPES[metric_payload[:type].to_sym]
            appsignal.public_send(metric_type, metric_name, metric_payload[:value], tags)
          end
        else
          return LogResult.new(false, "Invalid appsignal config")
        end

        LogResult.new(true)
      end
    end

    private

      attr_reader :decoratee, :allowed_tags
      alias_method :appsignal, :decoratee
  end
end
