class ImportsController < ChouetteController
  include PolicyChecker
  include RansackDateFilter
  include IevInterfaces
  skip_before_action :authenticate_user!, only: [:download]
  defaults resource_class: Import::Base, collection_name: 'imports', instance_name: 'import'
  before_action :notify_parents

  def download
    if params[:token] == resource.token_download
      send_file resource.file.path
    else
      user_not_authorized
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

  def notify_parents
    if Rails.env.development?
      ParentNotifier.new(Import::Base).notify_when_finished
    end
  end

  protected

   def begin_of_association_chain
    Workgroup.find(params[:workgroup_id])
  end
end
