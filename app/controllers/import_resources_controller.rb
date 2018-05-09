class ImportResourcesController < ChouetteController
  defaults resource_class: Import::Resource, collection_name: 'import_resources', instance_name: 'import_resource'
  respond_to :html
  belongs_to :import, :parent_class => Import::Base

  def index
    index! do |format|
      format.html {
        @import_resources = decorate_import_resources(@import_resources)
      }
    end
  end

  def download
    if params[:token] == resource.token_download
      send_file resource.file.path
    else
      user_not_authorized
    end
  end

  protected
  def collection
    @import_resources ||= parent.resources
  end

  def resource
    @import ||= Import::Base.find params[:import_id]
    @import_resource ||= begin
      import_resource = Import::Resource.find params[:id]
      raise ActiveRecord::RecordNotFound unless import_resource.import == @import
      import_resource
    end
  end

  private

  def decorate_import_resources(import_resources)
    ImportResourcesDecorator.decorate(import_resources)
  end
end
