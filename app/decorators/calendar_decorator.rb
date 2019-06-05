class CalendarDecorator < AF83::Decorator
  decorates Calendar
  set_scope { context[:workgroup] }
  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end
end
