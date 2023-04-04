class DocumentsController < ChouetteController
  include ApplicationHelper
  include PolicyChecker
  include Downloadable

  defaults resource_class: Document

  before_action :decorate_document, only: %i[show new edit create update]

  belongs_to :workbench

  def index
    index! do |format|
      format.html do
        @documents = DocumentDecorator.decorate(
          collection,
          context: {
            workbench: @workbench,
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

  def scope
    workbench.workgroup.documents
  end

  def search
    @search ||= Search::Document.new(scope, params, workgroup: workbench.workgroup)
  end

  alias document resource
  alias workbench parent
  delegate :collection, to: :search

  private

  def decorate_document
    @document = DocumentDecorator.decorate(
      params.key?(:id) ? document : build_resource,
      context: {
        workbench: @workbench
      }
    )
  end

  def document_params
    params.require(:document).permit(
      :name,
      :description,
      :file,
      :file_cache,
      :document_type_id,
      :document_provider_id,
      validity_period_attributes: [:from, :to],
      codes_attributes: [:id, :code_space_id, :value, :_destroy],
    )
  end
end
