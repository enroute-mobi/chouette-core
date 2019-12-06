if ENV['DD_AGENT_HOST']
  Datadog.configure do |c|
    app_name = ENV.fetch('DD_AGENT_APP', "chouette-core")
    debug = (ENV['DD_TRACE_DEBUG'] == 'true')
    env = ENV.fetch('DD_AGENT_ENV', "production")

    puts "Enable Datadog Agent for #{app_name}:#{env}"

    c.tracer debug: debug, tags: {app: app_name, env: env}

    service_context = (ENV['DELAYED_JOB_WORKER'] == 'true' ? "worker" : "front")
    if service_context == "worker"
      # To avoid Delayed::Backend::ActiveRecord::Job instantiation on 'active-record' service
      c.use :active_record, service_name: "#{app_name}-worker", orm_service_name: "#{app_name}-worker"
    end

    c.use :rails, service_name: "#{app_name}-front", cache_service: "#{app_name}-cache", controller_service: "#{app_name}-front", database_service: "#{app_name}-postgresql"
    c.use :delayed_job, service_name: "#{app_name}-worker"

    c.use :http, service_name: "#{app_name}-#{service_context}"
    c.use :faraday, service_name: "#{app_name}-#{service_context}"
    c.use :rake, service_name: "#{app_name}-rake"

    c.runtime_metrics_enabled = true
  end
end
