class NetworkDecorator < AF83::Decorator
  decorates Chouette::Network

  set_scope { context[:line_referential] }

  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end
end
