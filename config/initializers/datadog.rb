Datadog.configure do |c|
  c.use :rails, service_name: SmartEnv.fetch(:DATADOG_SERVICE_NAME, default: 'chouette-core')
  if Rails.env.production?
    c.tracer hostname: 'datadog-agent', port: 8126
  end
end
