module Redirect
  class VehicleJourneysController < BaseController
    def referential
      Referential.find(params[:referential_id])
    end

    def vehicle_journey
      referential.switch
      Chouette::VehicleJourney.find(params[:id])
    end

    def show
      redirect_to default_vehicle_journey_path(referential, vehicle_journey)
    end
  end
end
