class ProcessingRuleDecorator < AF83::Decorator
  decorates ProcessingRule

  set_scope { context[:workbench] }

  create_action_link

  with_instance_decorator(&:crud)

	define_instance_method :name do
		return unless processable

		"#{processable_type.text} - #{processable.name} - #{operation_step.text}"
	end

	define_instance_method :alpine_state do
		workbench = context[:workbench]

		state = {
			isWorkgroupOwner: workbench.organisation_id === workbench.workgroup.owner_id,
			processableType: processable_type,
			processableId: processable_id,
			operationStep: operation_step
		}

		JSON.generate(state)
	end

	define_instance_method :operation_step_options do
		ProcessingRule.operation_step.values.map do |value|
			h.content_tag(:option, value: value, selected: operation_step === value) { value.text }
		end.join.html_safe
	end

	define_instance_method :is_workgroup do |workbench_id|
		workbench_id != workbench.id ? I18n.t('yes') : I18n.t('no')
	end
end
