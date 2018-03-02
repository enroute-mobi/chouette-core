class ApplicationController < ActionController::Base
  include PaperTrailSupport
  include Pundit
  include FeatureChecker

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # TODO : Delete hack to authorize Cross Request for js and json get request from javascript
  protect_from_forgery unless: -> { request.get? && (request.format.json? || request.format.js?) }
  before_action :authenticate_user!
  before_action :set_locale


  # Load helpers in rails engine
  helper LanguageEngine::Engine.helpers

  def set_locale
    # I18n.locale = session[:language] || I18n.default_locale
    # For testing different locales w/o restarting the server
    I18n.locale = (params['lang'] || session[:language] || I18n.default_locale).to_sym
    logger.info "locale set to #{I18n.locale.inspect}"
  end

  def pundit_user
    UserContext.new(current_user, referential: @referential)
  end

  protected

  def user_not_authorized
    render 'errors/forbidden', status: :forbidden
  end

  def current_organisation
    current_user.organisation if current_user
  end
  helper_method :current_organisation

  def current_functional_scope
    functional_scope = current_organisation.sso_attributes.try(:[], "functional_scope") if current_organisation
    JSON.parse(functional_scope) if functional_scope
  end
  helper_method :current_functional_scope

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
end
