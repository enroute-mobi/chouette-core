class DocumentsController < ChouetteController
  include ApplicationHelper
  include PolicyChecker
  include Downloadable

  defaults resource_class: Document

  belongs_to :workbench

  def index
    index! do |format|
      format.html do
        @documents = DocumentDecorator.decorate(
          collection,
          context: {
            workbench: @workbench
          }
        )
      end
    end
  end

  def download
    prepare_for_download resource
    send_file resource.file.path, filename: resource.user_file.name, type: resource.user_file.content_type
  end

  protected

  alias document resource
  alias workbench parent

  def scope
    @scope ||= workbench.workgroup.documents
  end

  def resource
    get_resource_ivar || set_resource_ivar(scope.find_by_id(params[:id]).decorate(context: { workbench: @workbench }))
  end

  def build_resource
    get_resource_ivar || set_resource_ivar(end_of_association_chain.send(method_for_build,
                                                                         *resource_params).decorate(context: { workbench: @workbench }))
  end

  def search
    @search ||= Search::Document.new(scope, params, workgroup: workbench.workgroup)
  end
  delegate :collection, to: :search

  private

  def document_params
    params.require(:document).permit(
      :name,
      :description,
      :file,
      :file_cache,
      :document_type_id,
      :document_provider_id,
      validity_period_attributes: %i[from to],
      codes_attributes: %i[id code_space_id value _destroy]
    )
  end
end
