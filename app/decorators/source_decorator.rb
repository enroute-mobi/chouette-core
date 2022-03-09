class SourceDecorator < AF83::Decorator
  decorates Source

  set_scope { context[:workbench] }

  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end
end
