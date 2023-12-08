# frozen_string_literal: true

class DocumentMembershipsController < Chouette::ResourceController
  include ApplicationHelper
  include PolicyChecker

  defaults resource_class: DocumentMembership, collection_name: 'document_memberships',
           instance_name: 'document_membership'

  belongs_to :workbench
  belongs_to :line_referential, singleton: true
  belongs_to :line

  respond_to :js, only: :index

  def index
    @document_memberships = DocumentMembershipDecorator.decorate(document_memberships,
                                                                 context: decorator_context.merge(pagination_param_name: :document_memberships_page))
    @unassociated_documents_search = Search::Document.from_params(params, workgroup: workbench.workgroup)
    @unassociated_documents = DocumentDocumentMembershipDecorator.decorate(@unassociated_documents_search.search(unassociated_documents),
                                                                           context: decorator_context.merge(pagination_param_name: :unassociated_documents_page))
    index!
  end

  def create
    document_membership = build_resource
    if document_membership.save
      flash[:success] = I18n.t('documents.flash.associate.notice')
    else
      flash[:error] = I18n.t('documents.flash.associate.error')
    end
    redirect_to workbench_line_referential_line_document_memberships_path(workbench, line)
  end

  def destroy
    document_membership = resource.destroy
    if document_membership.destroyed?
      flash[:success] = I18n.t('documents.flash.unassociate.notice')
    else
      flash[:error] = I18n.t('documents.flash.unassociate.error')
    end
    redirect_to workbench_line_referential_line_document_memberships_path(workbench, line)
  end

  protected

  alias document_membership resource
  alias line parent

  def document
    workbench.documents.find(params[:document_id])
  end

  def build_resource
    get_resource_ivar || set_resource_ivar(document.memberships.build(documentable: line))
  end

  def resource
    get_resource_ivar || set_resource_ivar(line.document_memberships.find(params[:id]))
  end

  def document_memberships
    line.document_memberships.paginate(page: params[:document_memberships_page], per_page: 30)
  end

  def unassociated_documents
    if LinePolicy.new(pundit_user, line).update?
      workbench.documents.where.not(id: line.document_ids).paginate(page: params[:unassociated_documents_page],
                                                                    per_page: 30)
    else
      workbench.documents.none
    end
  end

  def workbench
    @workbench ||= current_organisation.workbenches.find(params[:workbench_id])
  end

  private

  def decorator_context
    {
      workbench: workbench,
      line: line
    }
  end
end
