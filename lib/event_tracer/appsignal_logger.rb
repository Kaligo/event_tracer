require_relative './metric_logger'

# NOTES
# Appsignal interface to send our usual actions
# BasicDecorator adds a transparent interface on top of the appsignal interface
#
# Usage: EventTracer.register :appsignal,
#          EventTracer::AppsignalLogger.new(Appsignal, allowed_tags: ['tag_1', 'tag_2'])
#
#        appsignal_logger.info metrics: [:counter_1, :counter_2]
#        appsignal_logger.info metrics: { counter_1: { type: :counter, value: 1 }, gauge_2: { type: :gauge, value: 10 } }
module EventTracer
  class AppsignalLogger < MetricLogger

    SUPPORTED_METRIC_TYPES = {
      counter: :increment_counter,
      distribution: :add_distribution_value,
      gauge: :set_gauge
    }.freeze
    DEFAULT_METRIC_TYPE = :increment_counter
    DEFAULT_COUNTER = 1

    def initialize(decoratee, allowed_tags: [])
      super(decoratee)
      @allowed_tags = allowed_tags.freeze
    end

    private

      def send_metric(metric_type, metric_name, value, tags)
        appsignal.public_send(metric_type, metric_name, value, tags)
      end

      def build_tags(args)
        args.slice(*allowed_tags)
      end

      alias_method :appsignal, :decoratee

  end
end
