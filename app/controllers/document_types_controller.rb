# frozen_string_literal: true

class DocumentTypesController < Chouette::WorkgroupController
  include ApplicationHelper

  defaults :resource_class => DocumentType

  before_action :decorate_document_type, only: %i[show new edit]
  after_action :decorate_document_type, only: %i[create update]

  before_action :document_type_params, only: [:create, :update]

  respond_to :html, :xml, :json

  def index # rubocop:disable Metrics/MethodLength
    index! do |format|
      format.html do
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end

        @document_types = DocumentTypeDecorator.decorate(
          collection,
          context: {
            workgroup: workgroup
          }
        )
      end
    end
  end

  protected

  alias document_type resource

  def collection
    @document_types = parent.document_types.paginate(page: params[:page], per_page: 30)
  end

  private


  def decorate_document_type
    object = document_type rescue build_resource
    @document_type = DocumentTypeDecorator.decorate(
      object,
      context: {
        workgroup: workgroup
      }
    )
  end

  def document_type_params
    params.require(:document_type).permit(
      :name,
      :short_name,
      :description
    )
  end
end
