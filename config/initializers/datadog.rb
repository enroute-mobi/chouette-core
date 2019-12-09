if ENV['DD_AGENT_HOST']
  Datadog.configure do |c|
    app_name = ENV.fetch('DD_AGENT_APP', "chouette-core")
    debug = (ENV['DD_TRACE_DEBUG'] == 'true')
    env = ENV.fetch('DD_AGENT_ENV', "production")
    service_context = ENV.fetch('DD_TRACE_CONTEXT',"front")

    puts "Enable Datadog Agent for #{app_name}-#{service_context}:#{env}"

    c.tracer debug: debug, tags: {app: app_name, env: env}

    if service_context != "front"
      # To avoid Delayed::Backend::ActiveRecord::Job and User/Organisation instantiations
      # on 'active-record' service
      active_record_service_name = "#{app_name}-#{service_context}"
      c.use :active_record, service_name: active_record_service_name, orm_service_name: active_record_service_name
    end

    c.use :rails, service_name: "#{app_name}-#{service_context}", cache_service: "#{app_name}-cache", controller_service: "#{app_name}-front", database_service: "#{app_name}-postgresql"
    c.use :delayed_job, service_name: "#{app_name}-worker"

    c.use :http, service_name: "#{app_name}-#{service_context}"
    c.use :faraday, service_name: "#{app_name}-#{service_context}"
    c.use :rake, service_name: "#{app_name}-rake"

    c.runtime_metrics_enabled = true
  end
end
