class Api::V1::DatasController < ActionController::Base
  before_action :load_publication_api
  before_action :check_auth_token, except: :infos

  rescue_from PublicationApi::InvalidAuthenticationError, with: :invalid_authentication_error
  rescue_from PublicationApi::MissingAuthenticationError, with: :missing_authentication_error

  def infos
    render layout: 'api'
  end

  def lines
    target = @publication_api&.workgroup&.output&.current
    unless target
      render :missing_file_error, layout: 'api', status: 404
      return
    end
    target.switch do
      CustomFieldsSupport.within_workgroup(@publication_api.workgroup) do
        @lines = target.lines
        puts @lines.inspect
        last_created_at_for_lines = ActiveRecord::Base.connection.select_rows "select line_id, max(created_at) from (#{Referential.last.metadatas.select('unnest(line_ids) as line_id', :created_at).to_sql}) as s group by line_id"
        @last_created_at_for_lines_hash = last_created_at_for_lines.to_h
        puts @last_created_at_for_lines_hash.inspect
        render :lines
      end
    end
  end

  def download_full
    source = @publication_api.publication_api_sources.find_by! key: params[:key]
    source.file.cache_stored_file!

    # fresh_men is invoked before send_file to obtain a valid Cache-Control header
    fresh_when(source, public: @publication_api.public?)
    send_file source.file.path, filename: source.public_url_filename
  end

  def download_line
    source = @publication_api.publication_api_sources.find_by! key: "#{params[:key]}-#{params[:line_id]}"
    if source.file.present?
      source.file.cache_stored_file!

      # fresh_men is invoked before send_file to obtain a valid Cache-Control header
      fresh_when(source, public: @publication_api.public?)
      send_file source.file.path, filename: source.public_url_filename
    else
      render :missing_file_error, layout: 'api', status: 404
    end
  end

  def graphql
    target = @publication_api&.workgroup&.output&.current
    unless target
      render :missing_file_error, layout: 'api', status: 404
      return
      # target = Referential.last # Kept here for test purpose, to remove
    end
    target.switch do
      CustomFieldsSupport.within_workgroup(@publication_api.workgroup) do
        variables = ensure_hash(params[:variables])
        query = params[:query]
        operation_name = params[:operationName]
        context = {
          target_referential: target
        }
        result = ChouetteSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
        render json: result
      end
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


end
