class RenderMacroPartial < ApplicationService
	attr_reader :macro, :template

	def initialize params
		@template = params[:template]
		@macro = Macro::Base.find_or_initialize_by(id: params[:id], type: params[:type])
		@macro.validate if params[:validate]
	end

	def call
		template.render(
			formats: [:html],
			partial: "macro_lists/macro",
			locals: {
        form: form,
        macro: macro
      }
		)
	end

	private

	def form
		@form ||= SimpleForm::FormBuilder.new('macro_list', Macro::List.new, template, wrapper: :horizontal_form)
	end
end
