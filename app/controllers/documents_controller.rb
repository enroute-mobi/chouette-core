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
      apply_scopes_if_available(
        document_provider_for_build.send(method_for_association_chain)
      ).send(method_for_build, *resource_params).decorate(context: { workbench: workbench })
    )
  end

  def update_resource(object, attributes)
    object.attributes = attributes[0]

    unless candidate_document_providers.include?(object.document_provider)
      object.valid? # validate the object before in order to compute all the other validations
      object.errors.add(:document_provider_id, :invalid)
    end

    object.save if object.errors.empty?
  end

  def search
    @search ||= Search::Document.from_params(params, workgroup: workbench.workgroup)
  end

  def collection
    @collection ||= search.search scope
  end

  def parent_for_parent_policy
    if params[:id]
      resource.document_provider
    else
      document_provider_for_build
    end
  end

  private

  def document_params
    @document_params ||= params.require(:document).permit(
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

  def document_provider_from_params
    return nil unless params[:document] && params[:document][:document_provider_id].present?

    current_workbench.document_providers.find(params[:document][:document_provider_id])
  end

  def document_provider_for_build
    @document_provider_for_build ||= document_provider_from_params || current_workbench.default_document_provider
  end

  def candidate_document_providers
    @candidate_document_providers ||= current_workbench.document_providers.order(:name)
  end
  helper_method :candidate_document_providers

  def candidate_document_types
    @candidate_document_types ||= current_workbench.workgroup.document_types.order(:name)
  end
  helper_method :candidate_document_types
end
