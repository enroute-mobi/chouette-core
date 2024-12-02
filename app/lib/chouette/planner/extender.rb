# frozen_string_literal: true

module Chouette
  module Planner
    module Extender
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
          def initialize(departure, arrival, validity_period: ValidityPeriod.new)
            self.departure = departure
            self.arrival = arrival
            self.validity_period = validity_period
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

      class WalkableStopAreas
        attr_accessor :stop_areas, :maximum_distance, :walk_speed

        def initialize(stop_areas, maximum_distance: 500, walk_speed: 1.3)
          self.stop_areas = stop_areas
          self.maximum_distance = maximum_distance
          self.walk_speed = walk_speed
        end

        def extend(journeys)
          Extend.new(self, journeys).extend
        end

        delegate :connection, to: :stop_areas
        delegate :select_rows, to: :connection

        class Extend < SimpleDelegator
          def initialize(extender, journeys)
            super extender
            @journeys = journeys
          end

          attr_reader :journeys

          def extend
            next_steps.each do |origin_step_id, next_step|
              extendable_journeys_by_last_id[origin_step_id].each do |journey|
                extended_journeys << journey.extend(next_step)
              end
            end

            extended_journeys
          end

          def next_steps
            select_rows(query).map do |step_id, stop_area_id, stop_area_latitude, stop_area_longitude, distance|
              step = Step::StopArea.new(
                stop_area_id: stop_area_id,
                position: Geo::Position.new(latitude: stop_area_latitude, longitude: stop_area_longitude),
                duration: distance / walk_speed
              )
              [step_id, step]
            end.to_h
          end

          def extended_journeys
            @extended_journeys ||= []
          end

          def extendable_journeys
            journeys.reject { |journey| journey.last.created_by == self.class }
          end

          def extendable_journeys_by_last
            extendable_journeys.group_by(&:last)
          end

          def extendable_journeys_by_last_id
            extendable_journeys_by_last.transform_keys(&:id)
          end

          def extendable_steps
            extendable_journeys_by_last.keys
          end

          def extendable_steps_sql
            extendable_steps.map { |s| "('#{s.id}',#{s.position.to_sql})" }.join(',')
          end

          def query
            <<~SQL
              select steps.id, scoped_stop_areas.id, scoped_stop_areas.latitude, scoped_stop_areas.longitude,
                ST_DistanceSphere(ST_SetSRID(ST_Point(scoped_stop_areas.longitude, scoped_stop_areas.latitude), 4326), steps.position)
              from (#{stop_areas.to_sql}) as scoped_stop_areas
              join (
                select *
                from ( values #{extendable_steps_sql} ) as t (id, position)
              ) steps
              on ST_DWithin(ST_SetSRID(ST_Point(scoped_stop_areas.longitude, scoped_stop_areas.latitude), 4326), steps.position, #{maximum_distance}, false)
            SQL
          end
        end
      end
    end
  end
end
