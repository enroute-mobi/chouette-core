# frozen_string_literal: true

module Fare
  class ZoneDecorator < Af83::Decorator
    decorates Fare::Zone

    set_scope { context[:workbench] }

    create_action_link

    with_instance_decorator(&:crud)

    def policy_parent
      context[:workbench].default_fare_provider
    end
  end
end
