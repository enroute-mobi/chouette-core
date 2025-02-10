Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  SmartEnv.set :PUBLIC_HOST, default: 'http://localhost:3000'
  SmartEnv.set :RAILS_HOST, default: 'http://localhost:3000'
  SmartEnv.set :IEV_URL, default: "http://localhost:8080"
  SmartEnv.set :BYPASS_AUTH_FOR_SIDEKIQ, default: true
  SmartEnv.set :REFERENTIALS_CLEANING_COOLDOWN, default: 30
  SmartEnv.set :ENABLE_LINK_TO_SUPPORT, default: true

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options)
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = true

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  config.action_mailer.default_url_options = { host: SmartEnv['PUBLIC_HOST'] }
  config.action_mailer.default_options     = { from: SmartEnv['MAIL_FROM'] }
  config.action_mailer.delivery_method     = ENV.fetch('MAIL_DELIVERY_METHOD','letter_opener').to_sym
  config.action_mailer.asset_host          = SmartEnv['PUBLIC_HOST']

  # See #8823
  config.chouette_email_user = true
  config.chouette_email_whitelist = '@enroute.mobi'

  # change to true to allow email to be sent during development
  config.action_mailer.perform_deliveries = true
  config.action_mailer.default :charset => "utf-8"

  # Configure the e-mail address which will be shown in Devise::Mailer
  config.mailer_sender = "noreply@enroute.mobi"
  config.to_prepare do
    Devise::Mailer.layout "mailer"
  end

  config.chouette_authentication_settings = {
    type: "database"
  }

  config.i18n.available_locales = [:fr, :en]

  config.serve_static_files = true

  config.middleware.insert_after(ActionDispatch::Static, Rack::LiveReload) if ENV['LIVERELOAD']

  if ENV['REDIS_URL']
    config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'], expires_in: 90.minutes }
  end

  config.subscriptions_notifications_recipients = %w{foo@example.com bar@example.com}

  config.to_prepare do
    Chouette::ChecksumManager.cleanup
  end

  config.after_initialize do
    Bullet.enable = ENV['CHOUETTE_BULLET_ENABLED'] == 'true'
    Bullet.rails_logger = true
  end

  config.logger_reopen_max = 2
  config.logger_reopen_size = 250.megabytes
end

Dir[File.join(File.dirname(__FILE__), File.basename(__FILE__, ".rb"), "*.rb")].each do |f|
  eval File.read(f), nil, f
end
