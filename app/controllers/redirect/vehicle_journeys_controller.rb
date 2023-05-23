module Redirect
  class VehicleJourneysController < BaseController
    include ReferentialSupport

    def vehicle_journey
      Chouette::VehicleJourney.find(params[:id])
    end

    def show
      redirect_to referential_line_route_vehicle_journeys_path referential, vehicle_journey.route.line,
                                                               vehicle_journey.route
    end
  end
end
