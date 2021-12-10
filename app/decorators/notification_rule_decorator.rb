class NotificationRuleDecorator < AF83::Decorator
  decorates NotificationRule
  set_scope { context[:workbench] }

  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.set_scope { [object.workbench] }

    instance_decorator.show_action_link do |l|
      l.href { h.workbench_notification_rule_path(object.workbench, object) }
    end

    instance_decorator.edit_action_link do |l|
      l.href { h.edit_workbench_notification_rule_path(object.workbench, object) }
    end
  
    instance_decorator.destroy_action_link do |l|
      l.href { h.workbench_notification_rule_path(object.workbench, object) }
    end
  end

  define_instance_method :name do
    NotificationRule.tmf('name', notification_type: "enumerize.notification_rule.notification_type.#{notification_type}".t, from: I18n.l(period.begin), to: I18n.l(period.end))
  end

  define_instance_method :user_items do
    users = context[:workbench].users.where(id: object.user_ids)

    Rabl::Renderer.new('autocomplete/users', users, format: :hash, view_path: 'app/views').render
  end

  define_instance_method :line_items do
    lines = context[:workbench].lines.where(id: object.line_ids)
  
    Rabl::Renderer.new('autocomplete/lines', lines, format: :hash, view_path: 'app/views').render
  end

  define_instance_method :operation_statuses_items do
    object.operation_statuses.map { |s| { id: s, text: s} }
  end

  define_instance_method :display_period do
    I18n.t('bounding_dates', debut: l(object.period.min), end: l(object.period.max))
  end

  define_instance_method :display_operation_statuses do
    case object.operation_statuses.size
    when 0, 3 then I18n.t("enumerize.notification_rule.operation_statuses.all")
    else
      object.operation_statuses.map { |o| I18n.t("enumerize.notification_rule.operation_statuses.#{o}") }.join(', ')
    end
  end
end
