class PublicationApiDecorator < Af83::Decorator
  decorates PublicationApi

  set_scope { context[:workgroup] }

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end
end
