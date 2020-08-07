class ShapeDecorator < AF83::Decorator
  decorates Shape

  set_scope { [context[:workbench], [:shape_referential]] }

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end
end
