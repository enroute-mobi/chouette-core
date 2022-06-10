class DocumentDecorator < AF83::Decorator
	decorates Document

  set_scope { context[:workbench] }

  create_action_link

	with_instance_decorator(&:crud)

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
end
