class PublicationApiKeyDecorator < Af83::Decorator
  decorates PublicationApiKey

  set_scope { [context[:workgroup], context[:publication_api]] }

  with_instance_decorator do |instance_decorator|
    instance_decorator.edit_action_link
    instance_decorator.destroy_action_link
  end
end
