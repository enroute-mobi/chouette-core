# frozen_string_literal: true

# Base Controller for all /api/v1/datas Controllers
module Api
  module V1
    module PublicationApi
      class BaseController < ::Api::V1::BaseController
        before_action :authenticate

        protected

        def publication_api
          @publication_api ||= ::PublicationApi.find_by! slug: params[:slug]
        end

        def workgroup
          @workgroup ||= publication_api.workgroup
        end

        def published_referential
          @published_referential ||= workgroup.output.current.tap do |referential|
            raise ActiveRecord::RecordNotFound unless referential
          end
        end

        def use_published_referential(&block)
          published_referential.switch do
            CustomFieldsSupport.within_workgroup(workgroup, &block)
          end
        end

        def authenticate
          return if publication_api.public?

          authenticate_or_request_with_http_token do |token, _options|
            publication_api.authenticate token
          end
        end
      end
    end
  end
end
