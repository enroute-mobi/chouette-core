Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

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

  config.action_mailer.default_url_options = { :host => 'localhost:3000' }
  config.action_mailer.default_options     = { from: 'Stif BOIV <stif-boiv@af83.com>' }
  config.action_mailer.delivery_method     = :letter_opener

  # change to true to allow email to be sent during development
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default :charset => "utf-8"

  # Configure the e-mail address which will be shown in Devise::Mailer
  config.mailer_sender = "appli@chouette.mobi"
  config.to_prepare do
    Devise::Mailer.layout "mailer"
  end

  # Specific theme for each company
  config.company_name = "STIF"
  config.company_theme = "#66b4e0"
  config.company_contact = "http://www.chouette.mobi/club-utilisateurs/contact-support/"
  config.accept_user_creation = false

  # Reflex api url
  config.reflex_api_url = "https://pprod.reflex.stif.info/ws/reflex/V1/service=getData"
  config.codifligne_api_url = "https://pprod.codifligne.stif.info/rest/v1/lc/getlist"

  if Rails.env.development? && ENV['NO_VPN']
    config.chouette_authentication_settings = {
      type: "database"
    }
  else
    config.chouette_authentication_settings = {
      type: "cas",
      cas_server: "http://stif-portail-dev.af83.priv/sessions"
    }
  end
  config.stif_portail_api =
    {
      key: "Ohphie1Voo6the5hohpi",
      url: "http://stif-portail-dev.af83.priv"
  }

  # Ext. apps links
  config.reflex_url = "https://195.46.215.128"
  config.codifligne_url = "https://pprod.codifligne.stif.info"
  config.portal_url = "http://stif-boiv-staging.af83.priv"

  # IEV url
  config.iev_url = "localhost:8080"

  # file to data for demo
  config.demo_data = "tmp/demo.zip"

  # link to validation specification pages
  config.validation_spec = "http://www.chouette.mobi/neptune-validation/v21/"

  config.i18n.available_locales = [:fr, :en]
end
