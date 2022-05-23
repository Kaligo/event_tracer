module EventTracer
  class PrometheusLogger < BasicDecorator

    SUPPORTED_METRIC_TYPES = {
      counter: :increment_count,
      gauge: :set_gauge
    }.freeze
    DEFAULT_INCREMENT = 1

    attr_reader :allowed_tags

    def initialize(prometheus, allowed_tags: [], default_tags: {}, raise_if_missing: true)
      super(prometheus)
      @allowed_tags = allowed_tags.freeze
      @default_tags = default_tags.freeze
      @raise_if_missing = raise_if_missing
    end

    LOG_TYPES.each do |log_type|
      define_method log_type do |**args|
        metrics = args[:metrics]

        return fail_result('Invalid metrics for Prometheus') unless valid_args?(metrics)
        return success_result if metrics.empty?

        labels = build_metric_labels(args)

        case metrics
        when Array
          metrics.each do |metric_name|
            increment_count(metric_name, DEFAULT_INCREMENT, labels: labels)
          end
        when Hash
          metrics.each do |metric_name, metric_payload|
            payload = metric_payload.transform_keys(&:to_sym)
            metric_type = SUPPORTED_METRIC_TYPES[payload.fetch(:type).to_sym]

            if metric_type
              send(
                metric_type,
                metric_name,
                payload.fetch(:value),
                labels: labels
              )
            end
          end
        end

        success_result
      end
    end

    private

      alias_method :prometheus, :decoratee

      attr_reader :default_tags, :raise_if_missing

      def valid_args?(metrics)
        metrics && (metrics.is_a?(Hash) || metrics.is_a?(Array))
      end

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

      def build_metric_labels(args)
        allowed_tags.inject(default_tags) do |metric_labels, tag|
          metric_labels.merge(tag => args[tag])
        end
      end

      def labels_for_registration
        (allowed_tags + default_tags.keys).uniq
      end
  end
end
