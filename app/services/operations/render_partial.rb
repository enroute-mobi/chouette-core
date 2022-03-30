module Operations
	class RenderPartial < ApplicationService
		attr_reader :resource, :klass, :parent_klass, :template, :form_options

		def initialize params
			@template = params[:template]
			@klass = params[:type].constantize
			@parent_klass = params[:parent_klass]
			@resource = klass.find_or_initialize_by(id: params[:id])

			@resource.validate if params[:validate]

			@form_options = { wrapper: :horizontal_form }

			if template.action_name === 'show'
				form_options[:defaults] = { disabled: true }
			end
		end

		def call
			template.render(
				formats: [:html],
				partial: "#{parent_klass.model_name.plural}/#{klass.superclass.model_name.i18n_key.to_s}",
				locals: {
					form: form,
					resource: resource
				}
			)
		end

		private

		def form
			@form ||= SimpleForm::FormBuilder.new(parent_klass.model_name.singular, parent_klass.new, template, form_options)
		end
	end
end
