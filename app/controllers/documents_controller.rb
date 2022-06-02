class DocumentsController < ChouetteController
  include ApplicationHelper
  include PolicyChecker

  defaults resource_class: Document

  before_action :decorate_document, only: %i[show new edit]

  belongs_to :workbench

  def create
    create! do |_success, failure|
      failure.html do
        decorate_document
        render 'new'
      end
    end
  end

  def update
    update! do |_success, failure|
      failure.html do
        decorate_document
        render 'edit'
      end
    end
  end

  def index
    index! do |format|
      format.html do
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end

        @documents = DocumentDecorator.decorate(
          collection,
          context: {
            workbench: @workbench,
          }
        )
      end
    end
  end

  protected

  alias document resource
  alias workbench parent

  def collection
    @documents = parent.documents.paginate(page: params[:page], per_page: 30)
  end

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
      :validity_period,
      :file,
      :file_cache,
      :document_type_id,
      :document_provider_id
    )
  end
end
