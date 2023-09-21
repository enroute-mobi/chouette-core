module Control
  class JourneyPatternSpeed < Control::Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :minimum_speed
        option :maximum_speed
        option :minimum_distance

        validates(
          :minimum_speed,
          :maximum_speed,
          :minimum_distance,
          numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: false }
        )
      end
    end
    include Options

    class Run < Control::Base::Run
      include Options

      def run
        analysis.anomalies.each do |anomaly|
          control_messages.create({
            message_attributes: {
              departure_name: anomaly.departure_name,
              departure_objectid: anomaly.departure_objectid,
              arrival_name: anomaly.arrival_name,
              arrival_objectid: anomaly.arrival_objectid,
              journey_pattern_name: anomaly.journey_pattern_name,
              position: anomaly.position,
              speed: anomaly.speed,
            },
            criticity: criticity,
            source_id: anomaly.journey_pattern_id,
            source_type: 'Chouette::JourneyPattern',
            message_key: :speed
          })
        end
      end

      def analysis
        @analysis ||= Analysis.new(journey_patterns, minimum_speed, maximum_speed, minimum_distance)
      end

      delegate :journey_patterns, to: :context

      class Analysis
        def initialize(journey_patterns, minimum_speed, maximum_speed, minimum_distance)
          @journey_patterns = journey_patterns
          @minimum_speed = minimum_speed
          @maximum_speed = maximum_speed
          @minimum_distance = minimum_distance
        end
        attr_reader :journey_patterns, :minimum_speed, :maximum_speed, :minimum_distance

        def anomalies
          PostgreSQLCursor::Cursor.new(query).map { |attributes| Anomaly.new(attributes) }
        end

        class Anomaly
          def initialize(attributes)
            attributes.each { |k, v| send "#{k}=", v if respond_to?(k) }
          end
          attr_accessor :journey_pattern_id, :journey_pattern_name, :departure_name, :departure_objectid,
                        :arrival_name, :arrival_objectid, :position, :speed
        end

        def query
          <<~SQL
            select journey_pattern_id,
              journey_pattern_name,
              departure_stop_areas.name as departure_name,
              departure_stop_areas.objectid  as departure_objectid,
              arrival_stop_areas.name as arrival_name,
              arrival_stop_areas.objectid  as arrival_objectid,
              position,
              speed
            from (
                select journey_pattern_id,
                  journey_pattern_name,
                  departure_id,
                  arrival_id,
                  position,
                  distance::float / duration::float * 3600 / 1000 AS speed
                from (
                    select journey_pattern_id,
                      name as journey_pattern_name,
                      departure_id,
                      arrival_id,
                      position,
                      coalesce(
                        ((journey_patterns.costs->>departure_arrival_ids)::jsonb->>'distance')::float,
                        straight_line_distance
                      ) as distance,
                      (
                        (journey_patterns.costs->>departure_arrival_ids)::jsonb->>'time'
                      )::float as duration
                    from (
                        select journey_pattern_id,
                          position,
                          departure_id,
                          arrival_id,
                          CONCAT(departure_id, '-', arrival_id) as departure_arrival_ids,
                          ST_DistanceSphere(departure, arrival) as straight_line_distance
                        from (
                            select journey_pattern_id,
                              stop_points.position as position,
                              LAG(stop_points.stop_area_id) OVER journey_pattern_stop_sequence as departure_id,
                              stop_points.stop_area_id as arrival_id,
                              ST_MakePoint(stop_areas.longitude, stop_areas.latitude) AS arrival,
                              ST_MakePoint(
                                LAG(stop_areas.longitude) OVER journey_pattern_stop_sequence,
                                LAG(stop_areas.latitude) OVER journey_pattern_stop_sequence
                              ) AS departure
                            from journey_patterns_stop_points
                              inner join stop_points on journey_patterns_stop_points.stop_point_id = stop_points.id
                              inner join public.stop_areas on stop_areas.id = stop_points.stop_area_id
                            where journey_pattern_id in (#{journey_patterns.select(:id).to_sql})
                            WINDOW journey_pattern_stop_sequence AS (
                              PARTITION BY journey_pattern_id
                              ORDER BY stop_points.position
                            )
                          ) as journey_pattern_departure_arrivals
                        where departure_id is not null
                      ) as journey_pattern_departure_arrival_with_costs
                      inner join journey_patterns on journey_pattern_id = journey_patterns.id
                  ) as journey_pattern_distance_durations
                where distance is not null
                  and duration is not null
                  and distance > 0
                  and duration > 0
                  and distance > #{minimum_distance}
              ) as journey_pattern_distance_speeds
            inner join public.stop_areas departure_stop_areas on departure_id = departure_stop_areas.id
            inner join public.stop_areas arrival_stop_areas on arrival_id = arrival_stop_areas.id
            where speed < #{minimum_speed}
              or speed > #{maximum_speed};
          SQL
        end
      end
    end
  end
end
