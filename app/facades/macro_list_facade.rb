class MacroListFacade
	attr_reader :macro_list, :template

	def initialize(macro_list, template)
		@macro_list = macro_list
		@template = template
	end

	def form_basename
		'macro_list'
	end

	def form_options
		{
			wrapper: :horizontal_form,
			html: {
				class: 'form-horizontal',
				id: 'macro_list_form',
				'x-data': '',
				'x-init': "$store.macroList.initState(#{json_state})",
				'@formdata': '$store.macroList.setFormData($event)'
			}
		}
	end

	def show?
		template.controller.action_name == 'show'
	end

	def transport_mode_options
		macro_list.workbench.workgroup.sorted_transport_modes.map { |t| ["enumerize.transport_mode.#{t}".t, t] }
	end

	def json_state
		JSON.generate({
			name: macro_list.name,
			comments: macro_list.comments,
			macros: macros(macro_list),
			macro_contexts: macro_contexts(macro_list)
		})
	end

	def macro_select_options store_collection
		{ name: 'macro_type', collection: Macro.available, store_collection: store_collection }
	end

	def macro_context_select_options
		{ name: 'macro_context_type', collection: Macro::Context.available, store_collection: '$store.macroList.contexts' }
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
    	html: Operations::RenderPartial.call(template: template, id: object.id, type: object.type, parent_klass: Macro::List, validate: true),
      **object.options
		}
	end
end
