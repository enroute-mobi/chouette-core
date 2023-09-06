class ShapeDecorator < AF83::Decorator
  decorates Shape

  set_scope { [context[:workbench], [:shape_referential]] }

  with_instance_decorator do |instance_decorator|
    # TODO CrossReferentialIndex needs to be fixed first to prevent multiple Referential.switch for each table entry
    # instance_decorator.action_link secondary: :show do |l|
    #   l.content t('shapes.actions.associated_resources')
    #   l.href do
    #     h.associations_workbench_shape_referential_shape_path(
    #       context[:workbench],
    #       object
    #     )
    #   end
    # end
    #
    instance_decorator.crud

  end
end