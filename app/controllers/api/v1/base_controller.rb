# frozen_string_literal: true

module Api
  module V1
    class BaseController < ::ActionController::API
      include ::ActionController::HttpAuthentication::Basic::ControllerMethods
      include ::ActionController::HttpAuthentication::Token::ControllerMethods
    end
  end
end
