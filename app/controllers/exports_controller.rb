class ExportsController < ChouetteController
  include PolicyChecker
  include RansackDateFilter
  include IevInterfaces
  skip_before_action :authenticate_user!, only: [:upload]
  skip_before_action :verify_authenticity_token, only: [:upload]
  defaults resource_class: Export::Base, collection_name: 'exports', instance_name: 'export'
  before_action :load_referentials, only: %i[new create]

  def upload
    if params[:token] == resource.token_upload
      resource.file = params[:file]
      resource.save!
      render json: {status: :ok}
    else
      user_not_authorized
    end
  end

  def show
    @export = ExportDecorator.decorate(@export)
    respond_to do |format|
      format.html
      format.json do
        fragment = render_to_string(partial: "exports/show", formats: :html)
        render json: {fragment: fragment}
      end
    end
  end

  def download
    resource.file.cache_stored_file!
    send_file resource.file.path, filename: resource.user_file.name, type: resource.user_file.content_type
  end

  protected

  def resource
    @export ||= parent.exports.find(params[:id])
  end

  def build_resource
    Export::Base.force_load_descendants if Rails.env.development?
  	@export ||= @parent.exports.new(creator: current_user.name)
  end

  private

  def index_model
    Export::Base
  end

  def export_params
    permitted_keys = %i(name type referential_id notification_target)
    export_class = params[:export] && params[:export][:type] && params[:export][:type].safe_constantize
    if export_class
      permitted_keys += export_class.options.map {|k, v| v[:name].presence || k }
    end
    export_params = params.require(:export).permit(permitted_keys)
    export_params[:user_id] ||= current_user.id
    export_params
  end

  def begin_of_association_chain
    parent
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
    referentials += parent.workgroup.output.referentials.pluck(:id)
    @referentials = Referential.where(id: referentials).order("created_at desc")
  end
end
