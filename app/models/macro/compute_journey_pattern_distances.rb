module Macro
  class ComputeJourneyPatternDistances < Macro::Base
    class Run < Macro::Base::Run
      def run
        calculators.journey_pattern_distances.each do |journey_pattern_distance|
          Updater.new(journey_pattern_distance, macro_messages).update
        end
      end

      def calculators
        @calculators ||= Calculator.new(journey_patterns)
      end

      class Updater
        def initialize(journey_pattern_distance, messages = nil)
          @journey_pattern_distance = journey_pattern_distance
          @messages = messages
        end
        attr_reader :journey_pattern_distance, :messages

        def update
          if journey_pattern.update costs: costs
            create_message criticity: 'info'
          else
            create_message criticity: 'warning', message_key: 'invalid_costs'
          end
        end

        def costs
          @costs ||=
            journey_pattern.costs.deep_merge(distances) do |_, current_value, new_value|
              current_value ? current_value : new_value
            end
        end

        def journey_pattern
          @journey_pattern ||= journey_pattern_distance.journey_pattern
        end

        def distances
          journey_pattern_distance.distances
        end

        def create_message(attributes)
          attributes.merge!(
            message_attributes: { name: journey_pattern.name },
            source: journey_pattern
          )
          messages.create!(attributes)
        end
      end

      class Calculator
        def initialize(journey_patterns)
          @journey_patterns = journey_patterns
        end
        attr_reader :journey_patterns

        def journey_pattern_distances
          JourneyPatternFinder.new(
            Query.new(journey_patterns).perform,
            journey_patterns
          ).batch
        end

        class JourneyPatternFinder
          def initialize(journey_pattern_distances, scope)
            @journey_pattern_distances = journey_pattern_distances
            @scope = scope
          end
          attr_reader :journey_pattern_distances, :scope

          def batch
            journey_pattern_distances.map do |attributes|
              JourneyPatternDistance.new(
                attributes.merge(
                  journey_pattern: journey_patterns.find{ |jp| jp.id == attributes['journey_pattern_id'].to_i }
                ),
              )
            end
          end

          def journey_patterns
            @journey_patterns ||= scope.where(id: journey_pattern_ids).to_a
          end

          def journey_pattern_ids
            @journey_pattern_ids ||= journey_pattern_distances.map { |attributes| attributes['journey_pattern_id'] }
          end
        end

        class Query
          def initialize(scope)
            @scope = scope
          end
          attr_reader :scope

          def perform
            query = <<~SQL
              SELECT
                journey_pattern_id,
                json_agg(
                  jsonb_build_object(
                    stop_area_pair,
                    jsonb_build_object('distance', avg_distance)
                  )
                ) AS distances
              FROM (
                SELECT
                  stop_area_pair,
                  journey_pattern_id AS journey_pattern_id,
                  avg(distance) AS avg_distance
                FROM (
                  SELECT
                    departure.journey_pattern_id AS journey_pattern_id,
                    departure.vehicle_journey_id AS vehicle_journey_id,	
                    (
                      SELECT 
                        ST_Length(
                          ST_LineSubstring(
                            arrival.geometry,
                            ST_LineLocatePoint(departure.geometry, departure.st_point),
                            ST_LineLocatePoint(arrival.geometry, arrival.st_point)
                          )::geography
                        )
                      FROM (#{base_query}) AS arrival
                      WHERE (arrival.position - departure.position) = 1
                        AND departure.vehicle_journey_id = arrival.vehicle_journey_id
                        AND departure.journey_pattern_id = arrival.journey_pattern_id
                        AND ST_LineLocatePoint(arrival.geometry, arrival.st_point) > ST_LineLocatePoint(departure.geometry, departure.st_point)
                      LIMIT 1
                    ) AS distance,
                    (
                      SELECT 
                        concat(departure.stop_area_id, '-', arrival.stop_area_id)
                      FROM (#{base_query}) AS arrival
                      WHERE (arrival.position - departure.position) = 1
                        AND departure.vehicle_journey_id = arrival.vehicle_journey_id
                        AND departure.journey_pattern_id = arrival.journey_pattern_id
                      LIMIT 1
                    ) AS stop_area_pair
                  FROM (#{base_query}) AS departure
                ) AS avg_distance_table
                WHERE stop_area_pair IS NOT NULL
                  AND distance IS NOT NULL
                GROUP BY stop_area_pair, journey_pattern_id
              ) AS journey_pattern_distances
              GROUP BY journey_pattern_id
            SQL

            PostgreSQLCursor::Cursor.new(query).to_a
          end
  
          def base_query
            scope
              .joins(:shape, vehicle_journey_at_stops: { stop_point: :stop_area })
              .select(select)
              .to_sql
          end

          def select
            <<~SQL
              journey_patterns.id AS journey_pattern_id,
              vehicle_journey_at_stops.vehicle_journey_id AS vehicle_journey_id,
              vehicle_journey_at_stops.departure_time AS departure_time,
              vehicle_journey_at_stops.arrival_time AS arrival_time,
              stop_points.position AS position,
              public.stop_areas.id AS stop_area_id,
              ST_SetSRID(ST_MakePoint(public.stop_areas.longitude, public.stop_areas.latitude), 4326) AS st_point,
              public.shapes.geometry AS geometry
            SQL
          end
        end

        class JourneyPatternDistance
          def initialize(attributes)
            attributes.each { |k, v| send "#{k}=", v if respond_to?(k) }
          end
          attr_accessor :journey_pattern

          def distances=(value)
            @distances = JSON.parse(value).reduce({}, :merge)
          end

          def distances
            @distances
          end
        end
      end

      def journey_patterns
        @journey_patterns ||= scope.journey_patterns
      end
    end
  end
end