require 'lograge/sql/extension'

Rails.application.configure do
  # Lograge config
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.colorize_logging = false

  config.lograge.keep_original_rails_log = true
  config.lograge.logger = ActiveSupport::Logger.new "#{Rails.root}/log/lograge_#{Rails.env}.log"

  config.lograge.custom_options = lambda do |event|
    payload = {
       params: event.payload[:params].reject { |k| %w(controller action).include? k },
       level: event.payload[:level],
       env: SmartEnv.fetch(:DATADOG_ENVIRONMENT, default: 'development')
    }
    if event.payload[:exception_object]
      payload[:error] = event.payload[:exception_object].message
      payload[:backtrace] = event.payload[:exception_object].backtrace
    end

    payload
  end
end
