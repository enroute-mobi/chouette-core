class DocumentDecorator < AF83::Decorator
	decorates Document

  set_scope { [context[:workbench], context[:parent]].compact }

  create_action_link

	with_instance_decorator do |i|
		i.show_action_link if: -> { !parent }
		i.edit_action_link if: -> { !parent }
		i.destroy_action_link if: -> { !parent }

		i.action_link(policy: :associate, if: -> { h.controller.is_a?(LineDocumentsController) && parent && !parent.document_ids.include?(object.id) }) do |l|
			l.content I18n.t('documents.actions.associate')
			l.method :put
			l.href { h.associate_workbench_line_referential_line_document_path(*scope, object) }
		end

		i.action_link(policy: :unassociate, if: -> { h.controller.is_a?(LineDocumentsController) && parent && parent.document_ids.include?(object.id) }) do |l|
			l.content I18n.t('documents.actions.unassociate')
			l.method :put
			l.href { h.unassociate_workbench_line_referential_line_document_path(*scope, object) }
		end
	end

	define_instance_method :display_validity_period_part do |part|
		value = validity_period.try(part)

		return '-' if value.nil?
		return '-' if value.is_a?(Float)

		I18n.l(value)
	end


	define_instance_method :json_state do
		JSON.generate({
			filename: file&.file&.identifier || '',
			errors: errors.messages.slice(:file, :validity_period).values
		})
	end

	define_instance_method :preview_json do
		JSON.generate({
			contentType: file.content_type,
			url: file.url
		})
	end

	define_instance_method(:parent) { context[:parent] }

	def pagination_param_name
		context[:pagination_param_name]
	end
end
