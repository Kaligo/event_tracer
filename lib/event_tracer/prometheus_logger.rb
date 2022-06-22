require_relative './metric_logger'

module EventTracer
  class PrometheusLogger < MetricLogger

    SUPPORTED_METRIC_TYPES = {
      counter: :increment_count,
      gauge: :set_gauge
    }.freeze
    DEFAULT_METRIC_TYPE = :increment_count
    DEFAULT_COUNTER = 1

    def initialize(prometheus, allowed_tags: [], default_tags: {}, raise_if_missing: true)
      super(prometheus)
      @allowed_tags = allowed_tags.freeze
      @default_tags = default_tags.freeze
      @raise_if_missing = raise_if_missing
    end

    private

      def send_metric(metric_type, metric_name, value, labels)
        send(metric_type, metric_name, value, labels: labels)
      end

      alias_method :prometheus, :decoratee

      attr_reader :raise_if_missing

      def increment_count(metric_name, value, labels:)
        metric = get_metric(metric_name.to_sym, :counter)
        metric.increment(by: value, labels: labels)
      end

      def set_gauge(metric_name, value, labels:)
        metric = get_metric(metric_name.to_sym, :gauge)
        metric.set(value, labels: labels)
      end

      def get_metric(metric_name, metric_type)
        metric = prometheus.get(metric_name)

        return metric if metric
        raise "Metric #{metric_name} not registered" if raise_if_missing

        prometheus.public_send(
          metric_type,
          metric_name,
          docstring: "A #{metric_type} for #{metric_name}",
          labels: labels_for_registration
        )
      end

      def build_tags(args)
        allowed_tags.inject(default_tags) do |metric_labels, tag|
          metric_labels.merge(tag => args[tag])
        end
      end

      def labels_for_registration
        (allowed_tags + default_tags.keys).uniq
      end
  end
end
