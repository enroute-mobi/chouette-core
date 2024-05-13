# frozen_string_literal: true

module Chouette
  class UserController < ApplicationController
    include Policy::Authorization

    before_action :authenticate_user!
    # already defined in ApplicationController but this declaration allows to put authenticate_user! before
    before_action :set_locale
    before_action :set_time_zone

    rescue_from ::ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ::Policy::NotAuthorizedError, with: :user_not_authorized

    alias user_not_authorized forbidden

    def policy_context_class
      Policy::Context::User
    end

    private

    def set_locale
      ::I18n.locale = ::LocaleSelector.locale_for(params, session, current_user)
    end

    def set_time_zone
      ::Time.zone = ::TimeZoneSelector.time_zone_for(current_user)
    end

    def begin_of_association_chain
      current_user
    end

    def current_organisation
      current_user&.organisation
    end
    helper_method :current_organisation

    def current_workgroup
      nil
    end
    helper_method :current_workgroup

    def current_workbench
      nil
    end
    helper_method :current_workbench
  end
end
