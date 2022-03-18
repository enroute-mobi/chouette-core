class ControlListFacade
	attr_reader :control_list, :workbench, :workgroup, :template

	def initialize(control_list, template)
		@control_list = control_list
		@workbench = control_list.workbench
		@workgroup = workbench.workgroup
		@template = template
	end

	def form_basename
		'control_list'
	end

	def form_options
		{
			wrapper: :horizontal_form,
			html: {
				class: 'form-horizontal',
				id: 'control_list_form',
				'x-data': '',
				'x-init': "$store.controlList.initState(#{json_state})",
				'@formdata': '$store.controlList.setFormData($event)'
			}
		}
	end

	def show?
		template.action_name == 'show'
	end

	def transport_mode_options
		workgroup.sorted_transport_modes.map { |t| ["enumerize.transport_mode.#{t}".t, t] }
	end

	def target_code_space_options
		workgroup.code_spaces.map { [c.name, c.id] }
	end

	def criticity_options
		option = Struct.new('Option', :id, :text)

		render_option = Proc.new do |key, color|
			template.content_tag :div, nil, class: 'mr-3' do
				template.concat template.content_tag :div, nil, class: 'span fa fa-circle', style: "color:#{color};"
				template.concat I18n.t("enumerize.control.criticity.#{key}")
			end
		end

		[
			option.new('warning', render_option.call('warning', '#ed7f00')),
			option.new('error', render_option.call('error', '#da2f36'))
		]
	end

	def target_attribute_options
		ModelAttribute.all.map { |m| { id: m.name, text: m.klass.tmf(m.name), resource_type: m.resource_name.to_s.camelcase } }.to_json
	end

	def json_state
		JSON.generate({
			name: control_list.name,
			comments: control_list.comments,
			controls: controls(control_list),
			control_contexts: control_contexts(control_list),
			is_show: show?
		})
	end

	def control_select_options store_collection
		{ name: 'control_type', collection: Control.available, store_collection: store_collection }
	end

	def control_context_select_options
		{ name: 'control_context_type', collection: Control::Context.available, store_collection: '$store.controlList.contexts' }
	end

	private

	def controls(object)
		object.controls.map do |control|
      control.attributes.slice('id', 'name', 'comments', 'criticity', 'code', 'type').merge(merged_options(control))
    end
	end

	def control_contexts(object)
		object.control_contexts.map do |control_context|
			control_context.attributes.slice('id', 'type').merge(
				controls: controls(control_context),
				**merged_options(control_context))
		end
	end

	def merged_options object
		{
			errors: object.errors.full_messages,
    	html: Operations::RenderPartial.call(template: template, id: object.id, type: object.type, parent_klass: Control::List, validate: true),
      **object.options
		}
	end
end
