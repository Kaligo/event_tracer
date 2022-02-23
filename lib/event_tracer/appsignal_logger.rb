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

    attr_reader :allowed_tags

    def initialize(decoratee, allowed_tags: [])
      super(decoratee)
      @allowed_tags = allowed_tags.freeze
    end

    LOG_TYPES.each do |log_type|
      define_method log_type do |**args|
        metrics = args[:metrics]

        return fail_result('Invalid appsignal config') unless valid_args?(metrics)
        return success_result if metrics.empty?

        tags = args.slice(*allowed_tags)

        case metrics
        when Array
          metrics.each do |metric|
            appsignal.public_send(DEFAULT_METRIC_TYPE, metric, DEFAULT_COUNTER, tags)
          end
        when Hash
          metrics.each do |metric_name, metric_payload|
            payload = metric_payload.transform_keys(&:to_sym)
            metric_type = SUPPORTED_METRIC_TYPES[payload.fetch(:type).to_sym]
            appsignal.public_send(metric_type, metric_name, payload.fetch(:value), tags) if metric_type
          end
        end

        success_result
      end
    end

    private

      alias_method :appsignal, :decoratee

      def valid_args?(metrics)
        metrics && (metrics.is_a?(Hash) || metrics.is_a?(Array))
      end
  end
end
