# frozen_string_literal: true

module Chouette
  class PrometheusExporter < Prometheus::Middleware::Exporter
    def call(env)
      Delayed::Metrics.measure

      super
    end
  end
end
