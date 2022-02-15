module MacroLists
	class RenderPartial < ApplicationService
		attr_reader :resource, :klass, :template

		def initialize params
			@template = params[:template]
			@klass = params[:type].constantize
			@resource = klass.find_or_initialize_by(id: params[:id])
			@resource.validate if params[:validate]
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
			@form ||= SimpleForm::FormBuilder.new('macro_list', Macro::List.new, template, wrapper: :horizontal_form)
		end
	end
end
