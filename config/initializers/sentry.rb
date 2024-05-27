# frozen_string_literal: true

if ENV['SENTRY_DSN']
  Sentry.init do |config|
    config.breadcrumbs_logger = %i[active_support_logger http_logger]
    config.release = Nest::Version.current.name

    # Disable transaction report
    config.enable_tracing = false
  end

  app = ENV.fetch 'SENTRY_APP', 'chouette-core'
  service_context = ENV.fetch 'SENTRY_CONTEXT', 'front'

  tags = { app: app, service: "#{app}-#{service_context}" }
  Sentry.set_tags(tags)

  puts "Sentry enabled with tags: #{tags.inspect}"
end
