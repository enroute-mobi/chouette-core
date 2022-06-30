class ProcessingRuleDecorator < AF83::Decorator
  decorates ProcessingRule

  set_scope { context[:workbench] }

	action_link on: :index, secondary: :index, policy: :create do |l|
		l.icon :plus
		l.content { I18n.t('processing_rules.actions.add_workgroup_rule') }
		l.href { h.add_workgroup_rule_workbench_processing_rules_path(context[:workbench]) }
	end

  create_action_link

  with_instance_decorator(&:crud)

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
			isWorkgroupOwner: workbench.organisation_id === workbench.workgroup.owner_id,
			processableType: processable_type,
			processableId: processable_id,
			operationStep: operation_step
		})
	end

	define_instance_method :operation_step_options do
		ProcessingRule.operation_step.values.map do |value|
			h.content_tag(:option, value: value, selected: operation_step === value) { value.text }
		end.join.html_safe
	end

	define_instance_method :target_workbench_ids_options do
		workbench.workgroup.workbenches.map do |w|
			{ id: w.id, text: w.name }
		end
	end

	define_instance_method :display_target_workbenches do
		return '-' if object.target_workbenches.empty?

		object.target_workbenches.map(&:name).join(', ')
	end

	define_instance_method(:workgroup?) { !!workgroup_id }
	define_instance_method(:workbench) { context[:workbench] }
end
