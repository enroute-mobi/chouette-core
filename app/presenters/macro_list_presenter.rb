class MacroListPresenter
	attr_reader :macro_list, :template

	def initialize(macro_list, template)
		@macro_list = macro_list
		@template = template
	end

	def transport_mode_options
		macro_list.workbench.workgroup.sorted_transport_modes.map { |t| ["enumerize.transport_mode.#{t}".t, t] }
	end

	def json_state
		JSON.generate({
			macros: macros(macro_list),
			macro_contexts: macro_contexts(macro_list)
		})
	end

	private

	def macros(object)
		object.macros.map do |macro|
      macro.attributes.slice('id', 'name', 'comments', 'type').merge(merged_options(macro))
    end
	end

	def macro_contexts(object)
		object.macro_contexts.map do |macro_context|
			macro_context.attributes.slice('id', 'type').merge(
				macros: macros(macro_context),
				**merged_options(macro_context))
		end
	end

	def merged_options object
		{
			errors: object.errors.full_messages,
    	html: MacroLists::RenderPartial.call(template: template, id: object.id, type: object.type, validate: true),
      **object.options
		}
	end
end
