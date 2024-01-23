# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include MetadataControllerSupport
  include FeatureChecker

  # TODO : Delete hack to authorize Cross Request for js and json get request from javascript
  protect_from_forgery unless: -> { request.get? && (request.format.json? || request.format.js?) }
  before_action :set_locale
  before_action :set_time_zone

  # Load helpers in rails engine
  helper LanguageEngine::Engine.helpers
  layout :layout_by_resource

  protected

  def set_locale
    ::I18n.locale = ::LocaleSelector.locale_for(params, session, nil)
  end

  def set_time_zone
  end

  include ErrorManagement

  def collection_name
    self.class.name.split("::").last.gsub('Controller', '').underscore
  end

  def decorated_collection
    if instance_variable_defined?("@#{collection_name}")
      instance_variable_get("@#{collection_name}")
    else
      nil
    end
  end
  helper_method :decorated_collection

  def begin_of_association_chain
    current_organisation
  end

  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  private

  def layout_by_resource
    if devise_controller?
      "devise"
    else
      "application"
    end
  end

end
