class NetworkDecorator < AF83::Decorator
  decorates Chouette::Network

  set_scope { [context[:workbench], :line_referential] }

  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end

  def policy_parent
    context[:workbench].default_line_provider
  end
end
