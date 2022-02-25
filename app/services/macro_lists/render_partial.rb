module MacroLists
	class RenderPartial < ApplicationService
		attr_reader :resource, :klass, :template, :form_options

		def initialize params
			@template = params[:template]
			@klass = params[:type].constantize
			@resource = klass.find_or_initialize_by(id: params[:id])
			@form_options = { wrapper: :horizontal_form }

			if template.action_name === 'show'
				form_options[:defaults] = { disabled: true }
			end
		end

		def call
			template.render(
				formats: [:html],
				partial: "macro_lists/#{klass.superclass.model_name.i18n_key.to_s}",
				locals: {
					form: form,
					resource: resource
				}
			)
		end

		private

		def form
			@form ||= SimpleForm::FormBuilder.new('macro_list', Macro::List.new, template, form_options)
		end
	end
end
