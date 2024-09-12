class StopAreaGroupDecorator < AF83::Decorator
  decorates StopAreaGroup

  set_scope { [ context[:workbench], :stop_area_referential ] }

  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end

  def policy_parent
    context[:workbench].default_stop_area_provider
  end
end
