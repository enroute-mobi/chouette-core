# frozen_string_literal: true

module Scope
  module VehicleJourney
    class FromTimeTables < Base
      collection :vehicle_journeys do
        current_collection.scheduled(global_scope.time_tables)
      end
    end
  end
end
