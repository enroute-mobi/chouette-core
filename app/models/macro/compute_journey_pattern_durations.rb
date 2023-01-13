# frozen_string_literal: true

module Macro
  class ComputeJourneyPatternDurations < Macro::Base
    class Run < Macro::Base::Run
      def run
        journey_patterns.find_in_batches do |batch|
          Batch.new(batch).journey_pattern_durations do |journey_pattern, durations|
            # [ Chouette::JourneyPattern, [{"12-13"=>300}, {"13-14"=>300}, {"14-15"=>300}, {"15-16"=>300}, {"16-17"=>300}] ]
            durations.each do |departure_arrival_duration|
              departure_arrival, duration = departure_arrival_duration.first

              journey_pattern.costs[departure_arrival] ||= {}
              journey_pattern.costs[departure_arrival][:time] ||= duration
            end

            journey_pattern.save
            create_message journey_pattern
          end
        end
      end

      # Create a message for the given JourneyPattern
      # If the JourneyPattern is invalid, an error message is created.
      def create_message(journey_pattern)
        attributes = {
          criticity: 'info',
          message_attributes: { name: journey_pattern.name },
          source: journey_pattern
        }

        attributes.merge!(criticity: 'error', message_key: 'error') unless journey_pattern.valid?

        macro_messages.create!(attributes)
      end

      # Compute durations for given JourneyPatterns
      class Batch
        def initialize(journey_patterns)
          @journey_patterns = journey_patterns.delete_if(&:full_schedule?)
        end
        attr_reader :journey_patterns

        def journey_patterns_by_id
          @journey_patterns_by_id ||= @journey_patterns.map { |j| [j.id, j] }.to_h
        end

        def journey_pattern_durations(&_block)
          # [ 42, {"13-14"=>300}, {"14-15"=>300}, {"15-16"=>300}, {"16-17"=>300}] ]
          query.each do |journey_pattern_id, durations|
            yield journey_patterns_by_id[journey_pattern_id], durations
          end
        end

        def query
          @query ||= Query.new(journey_patterns)
        end
      end

      class Query
        def initialize(journey_patterns)
          @journey_patterns = journey_patterns
        end
        attr_reader :journey_patterns

        def query
          <<~SQL
            SELECT journey_pattern_id,
              json_agg(
                jsonb_build_object(departure_arrival_ids, average_duration)
              ) AS durations
            FROM (
                SELECT departure_arrival_ids,
                  journey_pattern_id,
                  avg(duration)::integer AS average_duration
                FROM (
                    SELECT vehicle_journeys.journey_pattern_id,
                      concat(
                        LAG(stop_points.stop_area_id) OVER vehicle_journey_stops,
                        '-',
                        stop_points.stop_area_id
                      ) as departure_arrival_ids,
                      extract(
                        epoch
                        from arrival_time
                      ) - extract(
                        epoch
                        from (LAG(departure_time) OVER vehicle_journey_stops)
                      ) + (
                        arrival_day_offset - (
                          LAG(departure_day_offset) OVER vehicle_journey_stops
                        )
                      ) * 86400 as duration
                    FROM vehicle_journey_at_stops
                      inner join stop_points on vehicle_journey_at_stops.stop_point_id = stop_points.id
                      inner join vehicle_journeys on vehicle_journeys.journey_pattern_id in (#{journey_pattern_ids})
                        and vehicle_journey_at_stops.vehicle_journey_id = vehicle_journeys.id
                      WINDOW vehicle_journey_stops AS (
                        PARTITION BY vehicle_journey_id
                        ORDER BY stop_points.position
                      )
                  ) as durations_by_vehicle_journey
                WHERE duration IS NOT NULL
                GROUP BY departure_arrival_ids,
                  journey_pattern_id
              ) AS durations_by_journey_pattern
            GROUP BY journey_pattern_id;
          SQL
        end

        def durations
          ActiveRecord::Base.connection.select_rows(query)
        end

        def each(&_block)
          durations.each do |journey_pattern_id, durations_as_json|
            yield journey_pattern_id, JSON.parse(durations_as_json)
          end
        end

        def journey_pattern_ids
          journey_patterns.map(&:id).join(',')
        end
      end

      def journey_patterns
        @journey_patterns ||= scope.journey_patterns.includes(:route, :stop_points)
      end
    end
  end
end
