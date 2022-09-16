# frozen_string_literal: true

if ENV['DD_AGENT_HOST']
  Datadog.configure do |c|
    app_name = ENV.fetch('DD_AGENT_APP', 'chouette-core')
    service_context = ENV.fetch('DD_TRACE_CONTEXT', 'front')
    env = ENV.fetch('DD_AGENT_ENV', 'production')

    default_service = "#{app_name}-#{service_context}"

    puts "Enable Datadog Agent for #{default_service}:#{env}"

    partial_flush = ENV['DD_TRACE_PARTIAL_FLUSH'] && ENV['DD_TRACE_PARTIAL_FLUSH'] == 'true'
    partial_flush = (service_context == 'worker') if partial_flush.nil?

    puts "Enable partial flush: #{partial_flush}"

    c.service = default_service
    c.tags = { app: app_name }
    c.version = Nest::Version.current.name

    c.runtime_metrics.enabled = true
    c.tracing.partial_flush.enabled = partial_flush

    # Overrides default service names to include app name:
    c.tracing.instrument :rails, service_name: default_service
    c.tracing.instrument :active_record, service_name: "#{app_name}-postgresql"
    c.tracing.instrument :delayed_job, service_name: "#{app_name}-worker"
    c.tracing.instrument :faraday, service_name: default_service
    c.tracing.instrument :graphql, schemas: [ChouetteSchema], service_name: "#{app_name}-front"
    c.tracing.instrument :http, service_name: default_service
    c.tracing.instrument :rake, service_name: "#{app_name}-rake"
    c.tracing.instrument :redis, service_name: "#{app_name}-cache"

    c.logger.instance = Logger.new('log/datadog.log') if ENV['DD_TRACE_DEBUG']
  end
end
