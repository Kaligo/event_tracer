require_relative './basic_decorator'

module EventTracer
  class MetricLogger < BasicDecorator

    attr_reader :allowed_tags

    LOG_TYPES.each do |log_type|
      define_method log_type do |**args|
        metrics = args[:metrics]

        return fail_result("Invalid metrics for #{self.class.name}") unless valid_args?(metrics)
        return success_result if metrics.empty?

        tags = build_tags(args)

        case metrics
        when Array
          metrics.each do |metric|
            send_metric(self.class::DEFAULT_METRIC_TYPE, metric, self.class::DEFAULT_COUNTER, tags)
          end
        when Hash
          metrics.each do |metric_name, metric_payload|
            payload = metric_payload.transform_keys(&:to_sym)
            metric_type = self.class::SUPPORTED_METRIC_TYPES[payload.fetch(:type).to_sym]
            send_metric(metric_type, metric_name, payload.fetch(:value), tags) if metric_type
          end
        end

        success_result
      end
    end

    private

    attr_reader :default_tags

    def valid_args?(metrics)
      metrics && (metrics.is_a?(Hash) || metrics.is_a?(Array))
    end
  end
end
