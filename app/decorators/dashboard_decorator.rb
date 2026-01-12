# frozen_string_literal: true

class DashboardDecorator < Af83::Decorator
  decorates Dashboard

  set_scope { context[:workbench] }

  create_action_link

  with_instance_decorator(&:crud)
end