class RenderMacroPartial
	attr_reader :macro, :template, :macro_list_id, :index

	def initialize type:, template:, id: nil, macro_list_id: nil, index:
		@template = template
		@macro = Macro::Base.find_or_initialize_by(id: id, type: type)
		@macro_list_id = macro_list_id
		@index = index
	end

	def call
		{ html: html }
	end

	private

	def macro_list
		@macro_list ||= begin
			Macro::List.find(macro_list_id)
		rescue ActiveRecord::RecordNotFound
			Macro::List.new
		end
	end

	def form
		@form ||= SimpleForm::FormBuilder.new('macro_list', macro_list, template, wrapper: :horizontal_form)
	end

	def html
		template.render(
			formats: [:html],
			partial: "macro_lists/macro",
			locals: {
        form: form,
        macro: macro,
				index: index
      }
		)
	end


end
