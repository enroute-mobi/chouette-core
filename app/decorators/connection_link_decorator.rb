class ConnectionLinkDecorator < AF83::Decorator
  decorates Chouette::ConnectionLink

  set_scope { context[:stop_area_referential] }

  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.set_scope { object.stop_area_referential }

    instance_decorator.crud
  end
end
