# frozen_string_literal: true

module Redirect
  class VehicleJourneysController < ReferentialBaseController
    def vehicle_journey
      referential.vehicle_journeys.find(params[:id])
    end

    def show
      redirect_to workbench_referential_route_vehicle_journeys_path workbench, referential, vehicle_journey.route
    end
  end
end
