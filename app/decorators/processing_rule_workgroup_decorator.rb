# frozen_string_literal: true

class ProcessingRuleWorkgroupDecorator < Af83::Decorator
  decorates ProcessingRule::Workgroup

  set_scope { context[:workgroup] }

  create_action_link do |l|
    l.content { I18n.t('processing_rule/workgroups.actions.new') }
  end

  with_instance_decorator(&:crud)

  define_instance_method :name do
    "#{operation_step.text} #{display_processable}"
  end

  define_instance_method :display_processable do
    "#{working_processable.class.model_name.human}#{" (#{processable.name})" if processable}"
  end

  define_instance_method :processable_class_name do
    working_processable&.class&.name
  end

  define_instance_method :target_workbench_names do
    if object.target_workbenches.empty?
      I18n.t('all.masculine')
    else
      object.target_workbenches.map(&:name).join(', ')
    end
  end

  define_instance_method :excluded_workbench_names do
    if object.excluded_workbenches.empty?
      I18n.t('none')
    else
      object.excluded_workbenches.map(&:name).join(', ')
    end
  end
end
