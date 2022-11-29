module Control
  class Speed < Control::Base
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
          numericality: { only_integer: true, greater_than: 0, allow_nil: false }
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
              faulty_stop_area_pairs: anomaly.faulty_stop_area_pairs,
              journey_pattern_name: anomaly.journey_pattern_name
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

      class Analysis
        def initialize(scope, minimum_speed, maximum_speed, minimum_distance)
          @scope = scope
          @minimum_speed = minimum_speed
          @maximum_speed = maximum_speed
          @minimum_distance = minimum_distance
        end
        attr_reader :scope, :minimum_speed, :maximum_speed, :minimum_distance

        def anomalies
          PostgreSQLCursor::Cursor.new(query).map { |attributes| Anomaly.new(attributes) }
        end

        class Anomaly
          def initialize(attributes)
            attributes.each { |k,v| send "#{k}=", v if respond_to?(k) }
          end
          attr_accessor :faulty_stop_area_pairs, :journey_pattern_id, :journey_pattern_name
        end

        def query
          <<~SQL
            SELECT 
              speed_table.jp_id AS journey_pattern_id, 
              speed_table.jp_name AS journey_pattern_name,
              STRING_AGG(CONCAT(from_stop, ' - ', to_stop, ' (', speed, ' m/s', ')'), '; ') AS faulty_stop_area_pairs
            FROM (
              SELECT
                jp_id, jp_name,
                (
                  SELECT public.stop_areas.name
                  FROM public.stop_areas
                  WHERE public.stop_areas.id = split_part(from_to, '-', 1)::int
                ) AS from_stop,
                (
                  SELECT public.stop_areas.name
                  FROM public.stop_areas
                  WHERE public.stop_areas.id = split_part(from_to, '-', 2)::int
                ) AS to_stop,
                ((costs->>from_to)::json->>'distance')::float as distance,
                ((costs->>from_to)::json->>'distance')::float / ((costs->>from_to)::json->>'time')::float AS speed
              FROM (#{ base_sql }) AS base
            ) AS speed_table
            WHERE speed_table.distance > #{minimum_distance}
              AND (
                speed_table.speed > #{maximum_speed}
                OR speed_table.speed < #{minimum_speed}
              )
            GROUP BY speed_table.jp_id, speed_table.jp_name
          SQL
        end

        def base_sql
          scope.select(
            "jsonb_object_keys(costs) AS from_to,
            id AS jp_id,
            costs AS costs,
            name AS jp_name"
          ).to_sql
        end
      end

      def journey_patterns
        @Journey_patterns ||= context.journey_patterns
      end
    end
  end
end
