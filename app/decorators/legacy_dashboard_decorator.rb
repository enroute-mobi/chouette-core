# frozen_string_literal: true

class LegacyDashboardDecorator < Af83::Decorator
  decorates LegacyDashboard

  set_scope { context[:workbench] }

  create_action_link

  with_instance_decorator(&:crud)
end