Datadog.configure do |c|
  c.use :rails
  c.use :delayed_job
  c.use :faraday
  c.use :rake

  c.runtime_metrics_enabled = true
  c.tracer debug: true if ENV['DD_TRACE_DEBUG'] == 'true'
end
