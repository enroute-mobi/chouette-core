# frozen_string_literal: true

module Macro
  class DeleteVehicleJourneys < Base
    class Run < Macro::Base::Run
      def run
        vehicle_journeys.transaction do
          number_of_deleted_vehicle_journeys = vehicle_journeys.clean!

          macro_messages.create(
            message_attributes: {
              count: number_of_deleted_vehicle_journeys
            }
          )
        end
      end

      def vehicle_journeys
        scope.vehicle_journeys
      end
    end
  end
end
