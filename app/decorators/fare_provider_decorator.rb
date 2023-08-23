# frozen_string_literal: true
class FareProviderDecorator < AF83::Decorator
  decorates Fare::Provider

  set_scope { context[:workbench] }

  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end
end
