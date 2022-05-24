module EventTracer
  module Helpers
    module PrometheusHelper
      module_function

      def register_prometheus_metrics(prometheus_registry, type, name, labels, aggregation: nil)
        case type
        when :counter
          prometheus_registry.counter(
            name.to_sym,
            docstring: "A counter for #{name}",
            labels: labels
          )
        when :gauge
          prometheus_registry.gauge(
            name.to_sym,
            docstring: "A gauge for #{name}",
            labels: labels,
            store_settings: { aggregation: aggregation || :max }
          )
        end
      end
    end
  end
end
