# frozen_string_literal: true

class StopAreaReferentialDecorator < AF83::Decorator
  decorates StopAreaReferential

  set_scope { [context[:workbench]] }

  with_instance_decorator do |instance_decorator|
    instance_decorator.action_link primary: :show, policy: :edit do |l|
      l.content t('stop_area_referentials.actions.edit_params')
      l.href { h.edit_workbench_stop_area_referential_path context[:workbench] }
    end
  end
end
