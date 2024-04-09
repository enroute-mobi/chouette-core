class PublicationDecorator < AF83::Decorator
  decorates Publication

  set_scope { [context[:workgroup], context[:publication_setup]] }

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link
  end

end
