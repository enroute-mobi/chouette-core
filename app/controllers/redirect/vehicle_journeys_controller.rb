# frozen_string_literal: true

module Redirect
  class VehicleJourneysController < BaseController
    include ReferentialSupport

    def vehicle_journey
      referential.vehicle_journeys.find(params[:id])
    end

    def show
      redirect_to referential_route_vehicle_journeys_path referential, vehicle_journey.route
    end
  end
end
