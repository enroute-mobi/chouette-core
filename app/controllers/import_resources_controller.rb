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

  def workbench
    return unless params[:workbench_id]
    @workbench ||= current_organisation&.workbenches&.find(params[:workbench_id])
  end

  def workgroup
    return unless params[:workgroup_id]
    @workgroup ||= current_organisation&.workgroups.owned&.find(params[:workgroup_id])
  end

  def context
    @context ||= workgroup || workbench
  end

  def parent
    @parent ||= context.imports.find params[:import_id]
  end

  def collection
    @import_resources ||= parent.resources
  end

  def resource
    @import_resource ||= parent.resources.find params[:id]
  end

  private

  def decorate_import_resources(import_resources)
    ImportResourcesDecorator.decorate(import_resources)
  end
end
