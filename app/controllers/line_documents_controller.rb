class LineDocumentsController < ChouetteController
	include ApplicationHelper
  include PolicyChecker

  defaults resource_class: Document, collection_name: 'documents', instance_name: 'document'
	custom_actions resource: :associate, resource: :unassociate

	belongs_to :workbench
	belongs_to :line_referential, singleton: true
	belongs_to :line

	def index
		index! do |format|
			@documents = DocumentDecorator.decorate(documents, context: decorator_context.merge(pagination_param_name: :documents_page))
			@unassociated_documents_search = Search::Document.new(unassociated_documents, params)
			@unassociated_documents = DocumentDecorator.decorate(@unassociated_documents_search.collection, context: decorator_context.merge(pagination_param_name: :unassociated_documents_page))
    end
	end

	def associate
		document_membership = resource.memberships.build(documentable: line)
		if document_membership.save
			flash[:success] = I18n.t('documents.flash.associate.notice')
		else
			flash[:error] = I18n.t('documents.flash.associate.error')
		end
		redirect_to workbench_line_referential_line_documents_path(workbench, line)
	end

	def unassociate
		document_membership = resource.memberships.find_by!(documentable_id: line.id, documentable_type: line.class.name).destroy
		if document_membership.destroyed?
			flash[:success] = I18n.t('documents.flash.unassociate.notice')
		else
			flash[:error] = I18n.t('documents.flash.unassociate.error')
		end
		redirect_to workbench_line_referential_line_documents_path(workbench, line)
	end

	protected

	alias document resource
	alias line parent

	def resource
		get_resource_ivar || set_resource_ivar(workbench.documents.find(params[:id]))
	end

	def documents
		line.documents.paginate(page: params[:documents_page], per_page: 30)
	end

	def unassociated_documents
		workbench.documents.where.not(id: line.document_ids).paginate(page: params[:unassociated_documents_page], per_page: 30)
	end

	def workbench
		@workbench ||= current_organisation.workbenches.find(params[:workbench_id])
	end

	def line_referential
		@line_referential ||= workbench.line_referential
	end

	private

	def decorator_context
		{
			workbench: workbench,
			parent: line
		}
	end
end
