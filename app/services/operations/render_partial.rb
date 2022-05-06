module Operations
	class RenderPartial < ApplicationService
		attr_reader :resource, :klass, :parent_klass, :template, :form_options

		def initialize params
			@template = params[:template]
			@parent_klass = params[:parent_klass]
			@resource = params[:resource]

			@resource.validate if %w[create update].include?(@template.action_name)

			@form_options = { wrapper: :horizontal_form_tailwind }

		end

		def call
			template.render(
				formats: [:html],
				partial: "#{parent_klass.model_name.plural}/#{resource.class.superclass.model_name.i18n_key.to_s}",
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
