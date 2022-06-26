class DocumentDocumentMembershipDecorator < AF83::Decorator
	decorates Document

  set_scope { [context[:workbench], context[:line]] }

	with_instance_decorator do |instance_decorator|

		instance_decorator.action_link do |l|
			l.content I18n.t('documents.actions.associate')
			l.method :post
			l.href { h.workbench_line_referential_line_document_memberships_path(context[:workbench], context[:line], document_id: object.id) }
		end
	end

	def pagination_param_name
		context[:pagination_param_name]
	end
end
