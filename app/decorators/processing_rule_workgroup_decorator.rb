class ProcessingRuleWorkgroupDecorator < AF83::Decorator
  decorates ProcessingRule::Workgroup

  set_scope { context[:workgroup] }

  create_action_link do |l|
    l.content t('processing_rule/workgroups.actions.new')
  end

  with_instance_decorator(&:crud)

	define_instance_method :name do
		return unless processing

    I18n.t(
      'processing_rule/workgroups.name',
      processing_type: processing_type.text,
      operation_step: operation_step.text,
      processing_name: processing.name,
      target_workbenches: target_workbench_names
    )
	end

  define_instance_method :target_workbench_names do
    if object.target_workbenches.empty?
      'all.masculine'.t.capitalize
    else
      object.target_workbenches.map(&:name).join(', ')
    end
  end
end
