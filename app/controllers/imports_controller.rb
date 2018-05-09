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
    params.require(:import).permit(
      :name,
      :file,
      :type,
      :referential_id
    )
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
end
