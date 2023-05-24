class DocumentProvidersController < ChouetteController
  include ApplicationHelper
  include PolicyChecker

  defaults resource_class: DocumentProvider

  before_action :decorate_document_provider, only: %i[show new edit]
  after_action :decorate_document_provider, only: %i[create update]

  before_action :document_provider_params, only: [:create, :update]

  belongs_to :workbench

  def index
    index! do |format|
      format.html do
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end

        @document_providers = DocumentProviderDecorator.decorate(
          collection,
          context: {
            workbench: @workbench
          }
        )
      end
    end
  end

  protected

  alias document_provider resource
  alias workbench parent

  def scope
    @scope ||= workbench.document_providers
  end

  def collection
    @document_providers = parent.document_providers.paginate(page: params[:page], per_page: 30)
  end

  private

  def decorate_document_provider
    object = document_provider rescue build_resource
    @document_provider = DocumentProviderDecorator.decorate(
      object,
      context: {
        workbench: @workbench
      }
    )
  end

  def document_provider_params
    params.require(:document_provider).permit(
      :name,
      :short_name
    )
  end
end
