class Devise::CasSessionsController < Devise::SessionsController
  include DeviseCasAuthenticatable::SingleSignOut::DestroySession

  unless Rails.version =~/^4/
    unloadable
  end

  skip_before_action :verify_authenticity_token, only: [:single_sign_out]

  def new
    if memcache_checker.session_store_memcache? && !memcache_checker.alive?
      raise "memcache is down, can't get session data from it"
    end

    redirect_to(cas_login_url)
  end

  def service
    warden.authenticate!(:scope => resource_name)
    redirect_to after_sign_in_path_for(current_user)
  end

  def unregistered
  end

  def destroy message: nil
    # if :cas_create_user is false a CAS session might be open but not signed_in
    # in such case we destroy the session here
    if signed_in?(resource_name)
      sign_out(resource_name)
    else
      reset_session
    end

    if message
      redirect_to(cas_logout_url, flash: {alert: message})
    else
      redirect_to(cas_logout_url)
    end
  end

  def single_sign_out
    if ::Devise.cas_enable_single_sign_out
      session_index = read_session_index
      if session_index
        logger.debug "Intercepted single-sign-out request for CAS session #{session_index}."
        session_id = ::DeviseCasAuthenticatable::SingleSignOut::Strategies.current_strategy.find_session_id_by_index(session_index)
        if session_id
          logger.debug "Found Session ID #{session_id} with index key #{session_index}"
          destroy_cas_session(session_index, session_id)
        end
      else
        logger.warn "Ignoring CAS single-sign-out request as no session index could be parsed from the parameters."
      end
    else
      logger.warn "Ignoring CAS single-sign-out request as feature is not currently enabled."
    end

    head :ok
  end

  private

  def read_session_index
    if request.headers['CONTENT_TYPE'] =~ %r{^multipart/}
      false
    elsif request.post? && params['logoutRequest'] =~
        %r{^<samlp:LogoutRequest.*?<samlp:SessionIndex>(.*)</samlp:SessionIndex>}m
      $~[1]
    else
      false
    end
  end

  def destroy_cas_session(session_index, session_id)
    if destroy_session_by_id(session_id)
      logger.debug "Destroyed session #{session_id} corresponding to service ticket #{session_index}."
    end
    ::DeviseCasAuthenticatable::SingleSignOut::Strategies.current_strategy.delete_session_index(session_index)
  end

  def cas_login_url
    flash.clear # Fix 2742
    ::Devise.cas_client.add_service_to_login_url(cas_service_url)
  end
  helper_method :cas_login_url

  def request_url
    return @request_url if @request_url
    @request_url = request.protocol.dup
    @request_url << request.host
    @request_url << ":#{request.port.to_s}" unless request.port == 80
    @request_url
  end

  def cas_destination_url
    return unless ::Devise.cas_logout_url_param == 'destination'
    if !::Devise.cas_destination_url.blank?
      url = Devise.cas_destination_url
    else
      url = request_url.dup
      url << after_sign_out_path_for(resource_name)
    end
  end

  def cas_follow_url
    return unless ::Devise.cas_logout_url_param == 'follow'
    if !::Devise.cas_follow_url.blank?
      url = Devise.cas_follow_url
    else
      url = request_url.dup
      url << after_sign_out_path_for(resource_name)
    end
  end

  def cas_service_url
    if Rails.application.config.chouette_authentication_settings.try(:[], :cas_service_url)
      return Rails.application.config.chouette_authentication_settings[:cas_service_url]
    end

    ::Devise.cas_service_url(request.url.dup, devise_mapping)
  end

  def cas_logout_url
    begin
      ::Devise.cas_client.logout_url(cas_destination_url, cas_follow_url, cas_service_url)
    rescue ArgumentError
      # Older rubycas-clients don't accept a service_url
      ::Devise.cas_client.logout_url(cas_destination_url, cas_follow_url)
    end
  end

  def memcache_checker
    @memcache_checker ||= DeviseCasAuthenticatable::MemcacheChecker.new(Rails.configuration)
  end
end
