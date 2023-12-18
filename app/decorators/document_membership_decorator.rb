class DocumentMembershipDecorator < AF83::Decorator
	decorates DocumentMembership

  set_scope { [ context[:workbench], context[:documentable] ] }

	with_instance_decorator do |instance_decorator|

		instance_decorator.action_link(policy: :destroy) do |l|
			l.content I18n.t('documents.actions.unassociate')
			l.method :delete
			l.href { h.workbench_line_referential_line_document_membership_path(*scope, object) }
		end
	end


end
