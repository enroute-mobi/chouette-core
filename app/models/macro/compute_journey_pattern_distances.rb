# frozen_string_literal: true

module Macro
  class ComputeJourneyPatternDistances < Macro::Base
    class Run < Macro::Base::Run
      def run
        journey_patterns.find_in_batches do |batch|
          Batch.new(batch).journey_pattern_distances do |journey_pattern, distances|
            # [ Chouette::JourneyPattern, [{"12-13"=>300}, {"13-14"=>300}, {"14-15"=>300}, {"15-16"=>300}, {"16-17"=>300}] ]
            distances.each do |departure_arrival_distance|
              departure_arrival, distance = departure_arrival_distance.first

              journey_pattern.costs[departure_arrival] ||= {}
              journey_pattern.costs[departure_arrival][:distance] ||= distance
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
          message_attributes: { name: journey_pattern.name },
          source: journey_pattern
        }

        attributes.merge!(criticity: 'error', message_key: 'error') unless journey_pattern.valid?

        macro_messages.create!(attributes)
      end

      # Compute durations for given JourneyPatterns
      class Batch
        def initialize(journey_patterns)
          @journey_patterns = journey_patterns.delete_if(&:known_distance?)
        end
        attr_reader :journey_patterns

        def journey_patterns_by_id
          @journey_patterns_by_id ||= @journey_patterns.map { |j| [j.id, j] }.to_h
        end

        def journey_pattern_distances(&_block)
          # [ 42, {"13-14"=>300}, {"14-15"=>300}, {"15-16"=>300}, {"16-17"=>300}] ]
          query.each do |journey_pattern_id, distances|
            yield journey_patterns_by_id[journey_pattern_id], distances
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
            SELECT
              journey_pattern_id,
              json_agg(
                jsonb_build_object(departure_arrival_ids, distance)
              ) AS distances
            FROM (
                select journey_pattern_id,
                  departure_arrival_ids,
                  ROUND(
                    ST_Length(ST_GeogFromWKB(shapes.geometry)) * GREATEST(
                      0,
                      ST_LineLocatePoint(shapes.geometry, arrival_position) - ST_LineLocatePoint(shapes.geometry, departure_position)
                    )
                  ) as distance
                from (
                    select journey_pattern_id,
                      concat(
                        LAG(stop_points.stop_area_id) OVER journey_pattern_stop_sequence,
                        '-',
                        stop_points.stop_area_id
                      ) as departure_arrival_ids,
                      LAG(
                        ST_SetSRID(
                          ST_MakePoint(
                            public.stop_areas.longitude,
                            public.stop_areas.latitude
                          ),
                          4326
                        )
                      ) OVER journey_pattern_stop_sequence as departure_position,
                      ST_SetSRID(
                        ST_MakePoint(
                          public.stop_areas.longitude,
                          public.stop_areas.latitude
                        ),
                        4326
                      ) as arrival_position
                    from journey_patterns_stop_points
                      inner join stop_points on journey_patterns_stop_points.stop_point_id = stop_points.id
                      inner join public.stop_areas on public.stop_areas.latitude is not null
                      and public.stop_areas.longitude is not null
                      and stop_points.stop_area_id = public.stop_areas.id WINDOW journey_pattern_stop_sequence AS (
                        PARTITION BY journey_pattern_id
                        ORDER BY stop_points.position
                      )
                  ) as journey_pattern_departure_arrivals
                  inner join journey_patterns on journey_pattern_id = journey_patterns.id
                  inner join public.shapes on journey_patterns.shape_id = public.shapes.id
                where departure_position is not null
                  and arrival_position is not null
              ) as journey_pattern_distances
            GROUP BY journey_pattern_id;
          SQL
        end

        def distances
          ActiveRecord::Base.connection.select_rows(query)
        end

        def each(&_block)
          distances.each do |journey_pattern_id, distances_as_json|
            yield journey_pattern_id, JSON.parse(distances_as_json)
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
