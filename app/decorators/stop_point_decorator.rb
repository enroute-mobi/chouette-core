class StopPointDecorator < AF83::Decorator
  decorates Chouette::StopPoint

  set_scope { context[:workbench] }

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link do |l|
      l.href do
        h.workbench_stop_area_referential_stop_area_path(context[:workbench], object.stop_area)
      end
    end
  end
end
