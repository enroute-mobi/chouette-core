# frozen_string_literal: true

module Api
  module V1
    module Internals
      class BaseController < ::Api::V1::BaseController
        respond_to :json
        before_action :require_token

        def require_token
          authenticate_token || render_unauthorized('Access denied')
        end

        protected

        def render_unauthorized(message)
          render json: { errors: [{ detail: message }] }, status: :unauthorized
        end

        private

        def authenticate_token
          authenticate_with_http_token do |token|
            return true if Rails.application.secrets.api_token == token
          end
        end
      end
    end
  end
end
