class Api::V1::DatasController < ActionController::Base
  before_action :load_publication_api
  before_action :check_auth_token, except: :infos
  before_action :set_locale, only: 'infos'

  rescue_from PublicationApi::InvalidAuthenticationError, with: :invalid_authentication_error
  rescue_from PublicationApi::MissingAuthenticationError, with: :missing_authentication_error
  rescue_from PublicationApi::TooManyLinesError, with: :missing_file_error
  rescue_from PublicationApi::LineNotFoundError, with: :missing_file_error
  rescue_from PublicationApi::DocumentNotFoundError, with: :missing_file_error

  def infos
    render layout: 'api'
  end

  def download
    source = @publication_api.publication_api_sources.find_by! key: params[:key]

    if source.file.present?
      store_file_and_clean_cache(source)

      # fresh_men is invoked before send_file to obtain a valid Cache-Control header
      fresh_when(source, public: @publication_api.public?)
      send_file source.file.path, filename: source.public_url_filename
    else
      render :missing_file_error, layout: 'api', status: 404
    end
  end

  def redirect
    key = params[:key]
    # TODO Delete when legacy URLs are not longer required
    clean_key = key.gsub("-full", "")
    redirect_to "/api/v1/datas/#{params[:slug]}/#{clean_key}"
  end

  around_action :use_published_referential, only: [:lines, :graphql]

  def lines
    render json: published_referential.lines_status
  end

  def graphql
    variables = ensure_hash(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = {
      target_referential: published_referential
    }
    result = ChouetteSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
    render json: result
  end

  def line_document
    payload = params.slice(:registration_number, :document_type).merge(referential: published_referential).permit!.to_h.symbolize_keys
    document = PublicationApis::GetLineDocument.call(payload)
    filename = "#{params[:slug]}-line-#{payload[:registration_number]}-#{payload[:document_type]}-#{document.uuid}.#{document.file.file.extension}"

    send_file document.file.path, filename: filename
  end

  protected

  def set_locale
    I18n.locale = LocaleSelector.locale_for(params, session)
  end

  def use_published_referential
    unless published_referential
      render :missing_file_error, layout: 'api', status: 404
      return
    end
    published_referential.switch do
      CustomFieldsSupport.within_workgroup(workgroup) do
        yield
      end
    end
  end

  def workgroup
    @workgroup ||= @publication_api&.workgroup
  end

  def published_referential
    @published_referential ||= workgroup&.output&.current
  end

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

  # Handle form data, JSON body, or a blank value
  def ensure_hash(ambiguous_param)
    case ambiguous_param
    when String
      if ambiguous_param.present?
        ensure_hash(JSON.parse(ambiguous_param))
      else
        {}
      end
    when Hash, ActionController::Parameters
      ambiguous_param
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    end
  end

  def invalid_authentication_error
    render :invalid_authentication_error, layout: 'api', status: 401
  end

  def missing_authentication_error
    render :missing_authentication_error, layout: 'api', status: 401
  end

  def missing_file_error
    render :missing_file_error, layout: 'api', status: 404
  end

  def store_file_and_clean_cache(source)
    source.file.cache_stored_file!
    CarrierWave.clean_cached_files!
  end
end
