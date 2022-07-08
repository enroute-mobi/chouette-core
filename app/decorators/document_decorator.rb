class DocumentDecorator < AF83::Decorator
	decorates Document

  set_scope { context[:workbench] }

  create_action_link

	with_instance_decorator(&:crud)

	define_instance_method :display_validity_period_part do |part|
		value = validity_period.try(part)

		return '-' if value.nil?
		return '-' if value.is_a?(Float)

		I18n.l(value)
	end


	define_instance_method :json_state do
		JSON.generate({
			filename: file&.file&.filename || '',
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
