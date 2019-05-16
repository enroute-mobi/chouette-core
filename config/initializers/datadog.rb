Datadog.configure do |c|
  c.use :rails, service_name: 'chouette-core'
  if Rails.env.production?
    c.tracer hostname: 'datadog-agent', port: 8126
  end
end
