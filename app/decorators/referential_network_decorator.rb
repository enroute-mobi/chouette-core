class ReferentialNetworkDecorator < AF83::Decorator
  decorates Chouette::Network

  set_scope { context[:referential] }

  # Action links require:
  #   context: {
  #     referential: ,
  #   }

  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end
end
