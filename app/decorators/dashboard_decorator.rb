# frozen_string_literal: true

class DashboardDecorator < Af83::Decorator
  decorates Dashboard

  set_scope { context[:workbench] }

  create_action_link

  with_instance_decorator(&:crud)

  with_instance_decorator do |instance_decorator|
    instance_decorator.set_scope { [context[:workbench]] }

    instance_decorator.action_link(
      secondary: :show
    ) do |l|
      l.content { I18n.t('dashboards.actions.edit_layout') }
      l.href { h.edit_layout_workbench_dashboard_path(context[:workbench], object) }
      l.icon :th
    end
  end
end