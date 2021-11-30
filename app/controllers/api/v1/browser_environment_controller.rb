class Api::V1::BrowserEnvironmentController < ActionController::Base
  respond_to :json, only: [:show]
  layout false

  def show
    browser_environment = {
      dsn: ENV['SENTRY_DSN'],
      environment: ENV['SENTRY_CURRENT_ENV'],
      app: ENV['SENTRY_APP'],
      context: ENV['SENTRY_CONTEXT'],
    }
    render json: browser_environment.to_json
  end

end
