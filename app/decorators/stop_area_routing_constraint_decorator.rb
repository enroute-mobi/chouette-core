class StopAreaRoutingConstraintDecorator < AF83::Decorator
  decorates StopAreaRoutingConstraint

  set_scope { context[:referential] }
  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end
end
