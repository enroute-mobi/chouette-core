# frozen_string_literal: true

class VehicleJourneyDecorator < AF83::Decorator
  decorates Chouette::VehicleJourney

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link do |l|
      l.href do
        h.workbench_referential_route_vehicle_journeys_path(context[:workbench], referential, object.route)
      end
    end
  end
end
