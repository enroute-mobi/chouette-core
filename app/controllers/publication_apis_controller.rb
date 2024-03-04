# frozen_string_literal: true

class PublicationApisController < Chouette::WorkgroupController
  defaults :resource_class => PublicationApi

  def index
    index! do |format|
      format.html {
        @publication_apis = decorate_publication_apis(@publication_apis)
      }
    end
  end

  def show
    show! do |format|
      format.html {
        @publication_api_sources = @publication_api.publication_api_sources
        @api_keys = PublicationApiKeyDecorator.decorate(
          @publication_api.api_keys.order('created_at DESC').paginate(page: params[:page]),
          context: {
            workgroup: workgroup,
            publication_api: @publication_api
          }
        )
      }
    end
  end

  private

  def resource
    super.decorate(context: { workgroup: workgroup })
  end

  def collection
    scope = end_of_association_chain
    @publication_apis = scope.paginate(page: params[:page])
  end

  def decorate_publication_apis publication_apis
    PublicationApiDecorator.decorate(
      publication_apis,
      context: {
        workgroup: workgroup
      }
    )
  end

  def publication_api_params
    publication_api_params = params.require(:publication_api)
    permitted_keys = [:name, :slug, :public]
    publication_api_params.permit(permitted_keys)
  end
end
