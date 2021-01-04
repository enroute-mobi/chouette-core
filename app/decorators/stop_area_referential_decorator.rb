class StopAreaReferentialDecorator < AF83::Decorator
  decorates StopAreaReferential

  set_scope { [context[:workbench]] }

  with_instance_decorator do |instance_decorator|
    instance_decorator.action_link secondary: :show do |l|
      l.content { Chouette::StopArea.t.capitalize }
      l.href { h.workbench_stop_area_referential_stop_areas_path context[:workbench] }
    end

    instance_decorator.action_link primary: :show do |l|
      l.content t('stop_area_referentials.actions.edit_params')
      l.href { h.edit_workbench_stop_area_referential_path context[:workbench] }
    end

    instance_decorator.action_link policy: :synchronize, primary: :show do |l|
      l.content t('actions.sync')
      l.href { h.sync_workbench_stop_area_referential_path(context[:workbench]) }
      l.method :post
    end
  end
end
