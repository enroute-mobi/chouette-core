class NotificationRuleDecorator < AF83::Decorator
  decorates NotificationRule
  set_scope { context[:workbench] }

  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end

  define_instance_method :period_start do
    I18n.l(object.period&.min || Date.today, format: '%d/%m/%Y')
  end

  define_instance_method :period_end do
    I18n.l(object.period&.max || Date.today, format: '%d/%m/%Y')
  end

  define_instance_method :line_items do
    Rabl::Renderer.new('autocomplete/lines', object.lines, format: :hash, view_path: 'app/views').render
  end

  define_instance_method :operation_statuses_options do
    NotificationRule.operation_statuses.values.map {|i| {id: i, text: "#{NotificationRule.operation_statuses.i18n_scopes.first}.#{i}".t} }
  end
end
