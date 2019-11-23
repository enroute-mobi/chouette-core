Datadog.configure do |c|
  c.use :rails
  c.use :delayed_job
  # c.use :faraday
  # c.use :rake

  c.runtime_metrics_enabled = true
end
