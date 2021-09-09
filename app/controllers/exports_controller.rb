class ExportsController < ChouetteController
  include PolicyChecker
  include RansackDateFilter
  include IevInterfaces
  skip_before_action :authenticate_user!, only: [:upload]
  skip_before_action :verify_authenticity_token, only: [:upload]
  defaults resource_class: Export::Base, collection_name: 'exports', instance_name: 'export'
  before_action :load_referentials, only: %i[new create]

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

  protected

  def resource
    @export ||= parent.exports.find(params[:id])
  end

  def build_resource
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
    params.require(:export).permit(:name, :type, :referential_id, :notification_target, options: {}).tap do |export_params|
      export_params[:workbench_id] = workbench&.id
      export_params[:workgroup_id] = workgroup&.id || workbench&.workgroup&.id
      export_params[:creator] = current_user.name
      export_params[:user_id] = current_user.id
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
    referential_ids = parent.referentials.exportable.pluck(:id)
    referential_ids += (workgroup || workbench&.workgroup).output.referentials.pluck(:id)

    @referential_options = Rabl::Renderer.new(
      'autocomplete/referentials',
      Referential.where(id: referential_ids).order("created_at desc"),
      format: :hash,
      view_path: 'app/views'
    ).render
  end
end
