class ComplianceControlSetDecorator < AF83::Decorator
  decorates ComplianceControlSet

  create_action_link do |l|
    l.content t('compliance_control_sets.actions.new')
  end

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud

    instance_decorator.action_link policy: :clone, secondary: :show do |l|
      l.content t('actions.clone')
      l.href { h.clone_compliance_control_set_path(object.id) }
      l.icon :clone
    end
  end
end
