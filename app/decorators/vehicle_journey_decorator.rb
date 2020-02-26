class VehicleJourneyDecorator < AF83::Decorator
  decorates Chouette::VehicleJourney

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link do |l|
      l.href do
        h.referential_line_route_vehicle_journeys_path(referential, object.route.line, object.route)
      end
    end
  end
end
