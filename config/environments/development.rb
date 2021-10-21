require Rails.root + 'config/middlewares/cachesettings'

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

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  config.log_level = :debug
  config.colorize_logging = false
  config.logger = ActiveSupport::Logger.new("log/development.log", 3, 250.megabytes)

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
  #config.active_record.auto_explain_threshold_in_seconds = (RUBY_PLATFORM == "java" ? nil : 0.5)

  config.action_mailer.default_url_options = { host: SmartEnv['PUBLIC_HOST'] }
  config.action_mailer.default_options     = { from: SmartEnv['MAIL_FROM'] }
  config.action_mailer.delivery_method     = ENV.fetch('MAIL_DELIVERY_METHOD','letter_opener').to_sym
  config.action_mailer.asset_host          = SmartEnv['PUBLIC_HOST']

  # See #8823
  config.chouette_email_user = true
  config.chouette_email_whitelist = '@enroute.mobi'

  # change to true to allow email to be sent during development
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default :charset => "utf-8"

  # Configure the e-mail address which will be shown in Devise::Mailer
  config.mailer_sender = "noreply@enroute.mobi"
  config.to_prepare do
    Devise::Mailer.layout "mailer"
  end

  config.accept_user_creation = true

  config.chouette_authentication_settings = {
    type: "database"
  }

  config.i18n.available_locales = [:fr, :en]

  config.serve_static_files = true

  config.middleware.insert_after(ActionDispatch::Static, Rack::LiveReload) if ENV['LIVERELOAD']
  config.middleware.use I18n::JS::Middleware
  config.middleware.insert_after Rack::Sendfile, CacheSettings, {
    /\/assets\/.*/ => {
      cache_control: "max-age=86400, public",
      expires: 86400
    }
  }

  # config.cache_store = :redis_store, { url: "redis://localhost:6379/0/cache", expires_in: 90.minutes }

  config.subscriptions_notifications_recipients = %w{foo@example.com bar@example.com}
  config.automated_audits_recipients = %w{foo@example.com bar@example.com}

  config.additional_destinations << "dummy" << "mail"

  config.to_prepare do
    Chouette::ChecksumManager.cleanup
  end

end

Dir[File.join(File.dirname(__FILE__), File.basename(__FILE__, ".rb"), "*.rb")].each do |f|
  eval File.read(f), nil, f
end
