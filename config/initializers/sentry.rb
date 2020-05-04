if ENV['SENTRY_DSN']
  Raven.configure do |config|
    app = ENV.fetch 'SENTRY_APP', 'chouette-core'
    config.tags[:app] = app

    service_context = ENV.fetch 'SENTRY_CONTEXT', 'front'
    config.tags[:service] = "#{app}-#{service_context}"

    puts "Sentry enabled with tags: #{config.tags.inspect}"

    # Made by default
    # config.dsn = ENV['SENTRY_DSN']
  end
end
