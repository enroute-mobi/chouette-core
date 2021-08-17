Rails.application.configure do
  config.lograge.enabled = true

  config.lograge.ignore_actions = [
    'NotificationsController#index',
    'HealthCheck::HealthCheckController#index'
  ]
  config.colorize_logging = false

  config.lograge.custom_payload do |controller|
    Lograge::CustomPayload.new(controller).payload
  end

  config.lograge.formatter = Lograge::Formatters::Json.new
end

module Lograge
  class CustomPayload < Struct.new(:controller)

    def current(name)
      method = "current_#{name}"
      controller.send(method)&.id if respond_to?(method, true)
    end

    def user
      current :user
    end

    def workbench
      current :workbench
    end

    def workgroup
      current :workgroup
    end

    def locale
      I18n.locale
    end

    def correlation
      @correlation ||= Datadog.tracer.active_correlation
    end

    # From Datadog documentation:
    # https://docs.datadoghq.com/tracing/connect_logs_and_traces/ruby/#manual-lograge
    def dd
      {
        # To preserve precision during JSON serialization, use strings for large numbers
        trace_id: correlation.trace_id.to_s,
        span_id: correlation.span_id.to_s,
        # See CHOUETTE-1285
        # env: correlation.env.to_s,
        # service: correlation.service.to_s,
        # version: correlation.version.to_s
      } if correlation && correlation.trace_id != 0
    end

    def payload
      {}.tap do |payload|
        %i{user workbench workgroup locale dd}.each do |attribute|
          value = send attribute
          payload[attribute] = value if value
        end
      end
    end

  end
end
