# frozen_string_literal: true

class ProcessingRuleDecorator < Af83::Decorator
  decorates ProcessingRule::Workbench

  set_scope { context[:workbench] }

  create_action_link do |l|
    l.content { I18n.t('processing_rule/workbenches.actions.new') }
  end

  with_instance_decorator(&:crud)

  define_instance_method :name do
    "#{operation_step.text} #{processable.class.model_name.human} (#{processable.name})"
  end
end
