# frozen_string_literal: true

module Chouette
  module Planner
    module Extender
      class Walk
        def extend(journeys); end
      end

      class Mock
        def destinations
          @destinations ||= []
        end

        def register(departure, arrival, duration: 0, validity_period: nil)
          departure = Step.for(departure)
          arrival = Step.for(arrival, duration: duration)

          destinations << Destination.new(departure, arrival, validity_period: validity_period)
        end

        class Destination
          def initialize(departure, arrival, validity_period: nil)
            self.departure = departure
            self.arrival = arrival
            self.validity_period ||= ValidityPeriod.new
          end

          attr_accessor :departure, :arrival, :validity_period

          def extend(journey)
            return nil unless departure == journey.last

            journey.extend arrival, validity_period: validity_period
          end
        end

        def extend(journeys)
          extended_journeys = []

          journeys.each do |journey|
            destinations.each do |destination|
              extended_journey = destination.extend journey
              extended_journeys << extended_journey if extended_journey
            end
          end

          extended_journeys
        end
      end
    end
  end
end
