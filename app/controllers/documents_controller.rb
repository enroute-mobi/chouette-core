# frozen_string_literal: true

class DocumentsController < Chouette::WorkbenchController
  include ApplicationHelper
  include Downloadable

  defaults resource_class: Document

  # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action :authorize_resource, except: %i[new create index show download]
  # rubocop:enable Rails/LexicallyScopedActionFilter

  def index
    index! do |format|
      format.html do
        @documents = DocumentDecorator.decorate(
          collection,
          context: {
            workbench: workbench
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

  def scope
    @scope ||= workbench.workgroup.documents
  end

  def resource
    get_resource_ivar || set_resource_ivar(scope.find_by(id: params[:id]).decorate(context: { workbench: workbench }))
  end

  def build_resource
    get_resource_ivar || set_resource_ivar(
      end_of_association_chain.send(method_for_build, *resource_params).decorate(context: { workbench: workbench })
    )
  end

  def search
    @search ||= Search::Document.from_params(params, workgroup: workbench.workgroup)
  end

  def collection
    @collection ||= search.search scope
  end

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
