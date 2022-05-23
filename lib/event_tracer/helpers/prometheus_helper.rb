module EventTracer
  module Helpers
    module PrometheusHelper
      module_function

      def register_prometheus_metrics(prometheus_registry, name, labels)
        prometheus_registry.counter(
          name.to_sym,
          docstring: "A counter for #{name}",
          labels: labels
        )
      end
    end
  end
end
