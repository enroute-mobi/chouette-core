class LineRoutingConstraintZoneDecorator < AF83::Decorator
  decorates LineRoutingConstraintZone

  set_scope { [ context[:workbench], :line_referential ] }

  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end
end
