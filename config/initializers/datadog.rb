if ENV['DD_AGENT_HOST']
  Datadog.configure do |c|
    app_name = ENV.fetch('DD_AGENT_APP', "chouette-core")
    debug = (ENV['DD_TRACE_DEBUG'] == 'true')
    env = ENV.fetch('DD_AGENT_ENV', "production")

    puts "Enable Datadog Agent for #{app_name}:#{env}"

    c.tracer debug: debug, env:env

    c.use :rails, service_name: "#{app_name}-front", cache_service: "#{app_name}-cache", controller_service: "#{app_name}-front", database_service: "#{app_name}-postgresql"
    c.use :delayed_job, service_name: "#{app_name}-worker"
    c.use :faraday, service_name: "#{app_name}-http"
    c.use :rake, service_name: "#{app_name}-rake"

    c.runtime_metrics_enabled = true
  end
end
