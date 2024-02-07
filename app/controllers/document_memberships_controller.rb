# frozen_string_literal: true

class DocumentMembershipsController < Chouette::ResourceController
  include ApplicationHelper

  defaults resource_class: DocumentMembership, collection_name: 'document_memberships',
           instance_name: 'document_membership'

  belongs_to :workbench

  respond_to :js, only: :index

  def index
    @document_memberships = DocumentMembershipDecorator.decorate(
      document_memberships,
      context: decorator_context.merge(pagination_param_name: :document_memberships_page)
    )
    @unassociated_documents_search = Search::Document.from_params(params, workgroup: workbench.workgroup)
    @unassociated_documents = DocumentDocumentMembershipDecorator.decorate(
      @unassociated_documents_search.search(unassociated_documents),
      context: decorator_context.merge(pagination_param_name: :unassociated_documents_page)
    )
    index!
  end

  def create
    document_membership = build_resource
    if document_membership.save
      flash[:success] = I18n.t('documents.flash.associate.notice')
    else
      flash[:error] = I18n.t('documents.flash.associate.error')
    end
    redirect_to redirect_path
  end

  def destroy
    document_membership = resource.destroy
    if document_membership.destroyed?
      flash[:success] = I18n.t('documents.flash.unassociate.notice')
    else
      flash[:error] = I18n.t('documents.flash.unassociate.error')
    end
    redirect_to redirect_path
  end

  protected

  def authorize_resource_class
    authorize_policy(parent_policy, nil, build_resource)
  end

  alias document_membership resource
  alias documentable parent
  helper_method :documentable

  def document
    workbench.documents.find(params[:document_id])
  end

  def build_resource
    get_resource_ivar || set_resource_ivar(document.memberships.build(documentable: documentable))
  end

  def resource
    get_resource_ivar || set_resource_ivar(documentable.document_memberships.find(params[:id]))
  end

  def document_memberships
    documentable.document_memberships.paginate(page: params[:document_memberships_page], per_page: 30)
  end

  def unassociated_documents
    if parent_policy.update?
      workbench.documents.where.not(id: documentable.document_ids).paginate(page: params[:unassociated_documents_page],
                                                                            per_page: 30)
    else
      workbench.documents.none
    end
  end

  def workbench
    @workbench ||= current_organisation.workbenches.find(params[:workbench_id])
  end

  def collection_path_method
    raise NotImplementedError
  end

  def member_path_method
    raise NotImplementedError
  end

  private

  alias current_workbench workbench

  def decorator_context
    {
      workbench: workbench,
      documentable: documentable,
      collection_path_method: collection_path_method,
      member_path_method: member_path_method
    }
  end

  def redirect_path
    send(collection_path_method, workbench, documentable)
  end
end
