class StopPointDecorator < AF83::Decorator
  decorates Chouette::StopPoint

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link do |l|
      l.href do
        h.default_stop_area_path(object.stop_area)
      end
    end
  end
end
