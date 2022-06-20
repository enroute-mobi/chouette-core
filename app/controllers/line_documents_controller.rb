class LineDocumentsController < ChouetteController
	include ApplicationHelper
  include PolicyChecker

  defaults resource_class: Document, collection_name: 'documents', instance_name: 'document'

	belongs_to :workbench
	belongs_to :line_referential, singleton: true
	belongs_to :line

	def index
		index! do |format|
			@documents = DocumentDecorator.decorate(documents, context: decorator_context.merge(pagination_param_name: :documents_page))
			@unassociated_documents_search = Search::Document.new(unassociated_documents, params)
			@unassociated_documents = DocumentDecorator.decorate(@unassociated_documents_search.collection, context: decorator_context.merge(pagination_param_name: :unassociated_documents_page))

      format.html { render 'lines/documents/index' }

			format.js { render 'lines/documents/index' }
    end
	end

	def associate
		document = workbench.documents.find(params[:id])

		document.add_member(line)
		flash[:success] = I18n.t('documents.flash.associate.notice')
	rescue
		flash[:error] = I18n.t('documents.flash.associate.error')
	ensure
		redirect_back(fallback_location: workbench_line_referential_line_documents_path(workbench, line))
	end

	def unassociate
		document.remove_member(line)
		flash[:success] = I18n.t('documents.flash.unassociate.notice')
	rescue
		flash[:error] = I18n.t('documents.flash.unassociate.error')
	ensure
		redirect_back(fallback_location: workbench_line_referential_line_documents_path(workbench, line))
	end

	protected

	alias document resource
	alias line parent

	def documents
		line.documents.paginate(page: params[:documents_page], per_page: 30)
	end

	def unassociated_documents
		workbench.documents.where.not(id: line.document_ids).paginate(page: params[:unassociated_documents_page], per_page: 30)
	end

	def workbench
		@workbench ||= Workbench.find(params[:workbench_id])
	end

	def line_referential
		@line_referential ||= LineReferential.find(params[:line_referential_id])
	end

	private

	def search_params
	end

	def get_all_documents
		
	end

	def decorator_context
		{
			workbench: workbench,
			parent: line
		}
	end
end
