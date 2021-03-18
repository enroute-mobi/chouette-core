class ExportsController < ChouetteController
  include PolicyChecker
  include RansackDateFilter
  include IevInterfaces
  skip_before_action :authenticate_user!, only: [:upload]
  skip_before_action :verify_authenticity_token, only: [:upload]
  defaults resource_class: Export::Base, collection_name: 'exports', instance_name: 'export'
  before_action :load_referentials, only: %i[new create]
  
  helper_method :workbench

  # FIXME See CHOUETTE-207
  def upload
    resource = Export::Base.find params[:id]
    if params[:token] == resource.token_upload
      resource.file = params[:file]
      resource.save!
      render json: {status: :ok}
    else
      user_not_authorized
    end
  end

  def show
    @export = resource.decorate(context: {parent: parent})
    respond_to do |format|
      format.html
      format.json do
        fragment = render_to_string(partial: "exports/show", formats: :html)
        render json: {fragment: fragment}
      end
    end
  end

  def download
    store_file_and_clean_cache(resource)
    send_file resource.file.path, filename: resource.user_file.name, type: resource.user_file.content_type
  end

  def refresh_form
    if params[:type]
      type = params[:type].demodulize.underscore
      return render partial: "exports/types/#{type}"
    end

    if params[:exported_lines]
       return render partial: "exports/options/#{params[:exported_lines]}"
    end
  end

  protected

  def resource
    @export ||= parent.exports.find(params[:id])
  end

  def build_resource
    Export::Base.force_load_descendants if Rails.env.development?
    @export ||= Export::Base.new(*resource_params) do |export|
      export.workbench = workbench
      export.workgroup = workgroup || workbench&.workgroup
      export.creator   = current_user.name
    end
  end

  private

  def index_model
    Export::Base
  end

  def export_params
    permitted_keys = %i(name type referential_id notification_target)
    export_class = params[:export] && params[:export][:type] && params[:export][:type].safe_constantize

    if export_class
      permitted_keys += export_class.options.map { |k, v| v[:name].presence || k }
    end

    params.require(:export).permit(*permitted_keys, line_ids: []).tap do |_params|
      _params[:user_id] ||= current_user.id
      if export_class&.method_defined?(:line_ids)
        _params[:line_ids] = _params[:line_ids]&.flat_map { |str| JSON.parse(str) } || []
      end

      if export_class&.method_defined?(:duration)
        _params.delete(:period) == 'date_range' ?  _params[:duration].to_i : nil
      end
    end
  end

  def decorate_collection(exports)
    ExportDecorator.decorate(
      exports,
      context: {
        parent: parent
      }
    )
  end

  def load_referentials
    referentials = parent.referentials.exportable.pluck(:id)
    referentials += (workgroup || workbench&.workgroup).output.referentials.pluck(:id)
    @referentials = Referential.where(id: referentials).order("created_at desc")
  end
end
