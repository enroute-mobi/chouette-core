# frozen_string_literal: true
class Fare::ZoneDecorator < AF83::Decorator
  decorates Fare::Zone

  set_scope { context[:workbench] }

  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end
end
