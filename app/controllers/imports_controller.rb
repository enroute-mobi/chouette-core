class ImportsController < ChouetteController
  include PolicyChecker
  include RansackDateFilter
  include IevInterfaces
  skip_before_action :authenticate_user!, only: [:internal_download]
  defaults resource_class: Import::Base, collection_name: 'imports', instance_name: 'import'
  respond_to :json, :html

  def internal_download
    if params[:token] == resource.token_download
      resource.file.cache_stored_file!
      send_file resource.file.path
    else
      user_not_authorized
    end
  end

  def download
    resource.file.cache_stored_file!
    send_file resource.file.path, filename: resource.user_file.name, type: resource.user_file.content_type
  end

  def show
    instance_variable_set "@#{collection_name.singularize}", resource.decorate(context: {
      workbench: @workbench
    })
    respond_to do |format|
      format.html
      format.json do
        fragment = render_to_string(partial: "imports/#{@import.short_type}", formats: :html)
        render json: {fragment: fragment}
      end
    end
  end

  private

  def index_model
    Import::Workbench
  end

  def build_resource
    @import ||= Import::Workbench.new(*resource_params) do |import|
      import.workbench = parent
      import.creator   = current_user.name
    end
  end

  def import_params
    permitted_keys = %i(name file type referential_id notification_target)
    permitted_keys += Import::Workbench.options.keys
    import_params = params.require(:import).permit(permitted_keys)
    import_params[:user_id] ||= current_user.id
    import_params
  end

  def decorate_collection(imports)
    ImportDecorator.decorate(
      imports,
      context: {
        workbench: @workbench
      }
    )
  end

  protected

  def begin_of_association_chain
    return Workgroup.find(params[:workgroup_id]) if params[:workgroup_id]

    super
  end
end
