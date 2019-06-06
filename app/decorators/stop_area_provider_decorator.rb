class StopAreaProviderDecorator < AF83::Decorator
  decorates StopAreaProvider

  set_scope { context[:referential] }

  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end
end
