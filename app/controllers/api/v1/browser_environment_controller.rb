# frozen_string_literal: true

module Api
  module V1
    class BrowserEnvironmentController < BaseController
      respond_to :json, only: [:show]

      def show
        browser_environment = {
          sentry_dsn: ENV['SENTRY_DSN'],
          sentry_environment: ENV['SENTRY_CURRENT_ENV'],
          sentry_app: ENV['SENTRY_APP'],
          version: Nest::Version.current.name
        }.compact

        render json: browser_environment.to_json
      end
    end
  end
end
