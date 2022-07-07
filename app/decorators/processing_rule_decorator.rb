class ProcessingRuleDecorator < AF83::Decorator
  decorates ProcessingRule

  set_scope { context[:parent] }

	action_link on: :index, secondary: :index, policy: :create do |l|
		l.icon :plus
		l.content { I18n.t('processing_rules.actions.add_workgroup_rule') }
		l.href { h.new_workgroup_processing_rule_path(context[:workgroup]) }
	end

  create_action_link if: -> { context[:parent].is_a?(Workbench) }

  with_instance_decorator do |i|
		i.show_action_link { |l| l.href { [object.parent, object] } }
		i.edit_action_link { |l| l.href { [:edit, object.parent, object] } }
		i.destroy_action_link { |l| l.href { [object.parent, object] } }
	end

	define_instance_method :name do
		return unless processable

		I18n.t(
			'processing_rules.name',
			processable_type: processable_type.text,
			operation_step: operation_step.text,
			processable_name: processable.name,
			target_workbenches: object.target_workbenches.empty? ? 'all.masculine'.t : display_target_workbenches
		)
	end

	define_instance_method :alpine_state do
		JSON.generate({
			isWorkgroupOwner: workgroup? || object.workbench.organisation_id === object.workbench.workgroup.owner_id,
			processableType: processable_type,
			processableId: processable_id,
			operationStep: operation_step,
			baseURL: h.url_for([object.parent, :processing_rules])
		})
	end

	define_instance_method :operation_step_options do
		ProcessingRule.operation_step.values.map do |value|
			h.content_tag(:option, value: value, selected: operation_step === value) { value.text }
		end.join.html_safe
	end

	define_instance_method :target_workbench_ids_options do
		object.workgroup.workbenches.map do |w|
			{ id: w.id, text: w.name }
		end
	end

	define_instance_method :display_target_workbenches do
		return '-' if object.target_workbenches.empty?

		object.target_workbenches.map(&:name).join(', ')
	end

	define_instance_method(:workgroup?) { object.parent.is_a?(Workgroup) }
end
