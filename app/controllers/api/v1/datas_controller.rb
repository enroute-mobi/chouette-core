class Api::V1::DatasController < ActionController::Base
  before_action :load_publication_api
  before_action :check_auth_token, except: :infos

  rescue_from PublicationApi::InvalidAuthenticationError, with: :invalid_authentication_error
  rescue_from PublicationApi::MissingAuthenticationError, with: :missing_authentication_error

  def infos
    render layout: 'api'
  end

  def invalid_authentication_error
    render :invalid_authentication_error, layout: 'api', status: 401
  end

  def missing_authentication_error
    render :missing_authentication_error, layout: 'api', status: 401
  end

  def download_full
    source = @publication_api.publication_api_sources.find_by! key: params[:key]
    source.file.cache_stored_file!

    send_file source.file.path
  end

  def download_line
    source = @publication_api.publication_api_sources.find_by! key: "#{params[:key]}-#{params[:line_id]}"
    if source.file.present?
      source.file.cache_stored_file!
      send_file source.file.path
    else
      render :missing_file_error, layout: 'api', status: 404
    end
  end

  protected

  def load_publication_api
    @publication_api = PublicationApi.find_by! slug: params[:slug]
  end

  def check_auth_token
    return if @publication_api.public?
    key = nil
    authenticate_with_http_token do |token|
      key = @publication_api.api_keys.find_by token: token
      raise PublicationApi::InvalidAuthenticationError unless key
      return true
    end
    raise PublicationApi::MissingAuthenticationError unless key
  end
end
