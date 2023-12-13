# frozen_string_literal: true

module Chouette
  class UserController < ApplicationController
    include MetadataControllerSupport
    include Pundit

    before_action :authenticate_user!
    before_action :set_locale, unless: -> { params[:controller] == 'notifications' }
    before_action :set_time_zone

    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

    alias user_not_authorized forbidden

    private

    def set_locale
      ::I18n.locale = ::LocaleSelector.locale_for(params, session, current_user)
    end

    def set_time_zone
      ::Time.zone = ::TimeZoneSelector.time_zone_for(current_user)
    end

    def pundit_user
      ::UserContext.new(current_user, referential: @referential, workbench: current_workbench, workgroup: current_workgroup)
    end

    def current_organisation
      current_user.organisation if current_user
    end
    helper_method :current_organisation

    def current_workbench
      nil
    end

    def current_workgroup
      nil
    end
  end
end
