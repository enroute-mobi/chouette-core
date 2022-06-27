class LineProviderDecorator < AF83::Decorator
  decorates LineProvider

  set_scope { [context[:workbench], :line_referential] }

  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end
end
