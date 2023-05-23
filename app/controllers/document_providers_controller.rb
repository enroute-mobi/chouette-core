class DocumentProvidersController < ChouetteController
  include ApplicationHelper
  include PolicyChecker

  defaults resource_class: DocumentProvider

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

  def resource
    get_resource_ivar || set_resource_ivar(scope.find_by_id(params[:id]).decorate(context: { workbench: @workbench }))
  end

  def build_resource
    get_resource_ivar || set_resource_ivar(end_of_association_chain.send(method_for_build,
                                                                         *resource_params).decorate(context: { workbench: @workbench }))
  end

  private

  def document_provider_params
    params.require(:document_provider).permit(
      :name,
      :short_name
    )
  end
end
