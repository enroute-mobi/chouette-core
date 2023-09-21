# frozen_string_literal: true
class Fare::ProviderDecorator < AF83::Decorator
  decorates Fare::Provider

  set_scope { context[:workbench] }

  create_action_link

  with_instance_decorator(&:crud)
end
