class ProcessingRuleDecorator < AF83::Decorator
  decorates ProcessingRule::Workbench

  set_scope { context[:workbench] }

  create_action_link do |l|
    l.content t('processing_rule/workbenches.actions.new')
  end

  with_instance_decorator(&:crud)

	define_instance_method :name do
		return unless processing

		I18n.t(
			'processing_rule/workbenches.name',
			processing_type: processing_type.text,
			operation_step: operation_step.text,
			processing_name: processing.name
		)
	end
end
