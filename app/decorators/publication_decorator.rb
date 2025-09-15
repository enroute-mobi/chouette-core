class PublicationDecorator < Af83::Decorator
  decorates Publication

  set_scope { [context[:workgroup]] }

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link do |l|
      l.href { [scope, object.publication_setup, object] }
    end
  end
end
