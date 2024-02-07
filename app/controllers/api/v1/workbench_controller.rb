# frozen_string_literal: true

module Api
  module V1
    class WorkbenchController < BaseController
      respond_to :json

      before_action :authenticate

      protected

      def current_workbench
        @current_workbench
      end

      private

      def authentication_scope
        Workbench.find(params[:workbench_id]).api_keys
      end

      def authentication_scheme
        ActionController::HttpAuthentication::Basic.auth_scheme(request)&.downcase&.to_sym
      end

      def authenticate_or_request(&block)
        if authentication_scheme == :basic
          authenticate_or_request_with_http_basic do |username, password|
            Authentication.new(authentication_scope, token: password, organisation_code: username).validate(&block)
          end
        else
          authenticate_or_request_with_http_token do |token|
            Authentication.new(authentication_scope, token: token).validate(&block)
          end
        end
      rescue ActiveRecord::RecordNotFound
        request_http_token_authentication
      end

      def authenticate
        authenticate_or_request do |authentication|
          @current_workbench = authentication.workbench
        end
      end

      class Authentication

        def initialize(scope, token:, organisation_code: nil)
          @scope, @token, @organisation_code = scope, token, organisation_code
        end

        attr_accessor :scope, :token, :organisation_code

        def api_key
          @api_key ||= scope.find_by token: token
        end

        def validate(&block)
          if valid?
            block.call self
            true
          else
            false
          end
        end

        def valid?
          api_key.present? && valid_organisation_code?
        end

        def valid_organisation_code?
          return true unless organisation_code
          organisation_code == organisation&.code
        end

        def organisation
          workbench&.organisation
        end

        def workbench
          api_key&.workbench
        end

      end
    end
  end
end
