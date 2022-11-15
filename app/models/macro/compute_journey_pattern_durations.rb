module Macro
  class ComputeJourneyPatternDurations < Macro::Base
    class Run < Macro::Base::Run
      def run
        calculators.journey_pattern_durations.each do |journey_pattern_duration|
          Updater.new(journey_pattern_duration, macro_messages).update
        end
      end

      def calculators
        @calculators ||= Calculator.new(journey_patterns)
      end

      class Updater
        def initialize(journey_pattern_duration, messages = nil)
          @journey_pattern_duration = journey_pattern_duration
          @messages = messages
        end
        attr_reader :journey_pattern_duration, :messages

        def update
          if journey_pattern.update costs: costs
            create_message criticity: 'info'
          else
            create_message criticity: 'warning', message_key: 'invalid_costs'
          end
        end

        def costs
          @costs ||=
            journey_pattern.costs.deep_merge(durations) do |key, current_value, new_value|
              current_value ? current_value : new_value
            end
        end

        def journey_pattern
          @journey_pattern ||= journey_pattern_duration.journey_pattern
        end

        def durations
          journey_pattern_duration.durations
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

        def journey_pattern_durations
          JourneyPatternFinder.new(
            Query.new(journey_patterns).perform,
            journey_patterns
          ).find_all
        end

        class JourneyPatternFinder
          def initialize(journey_pattern_durations, scope)
            @journey_pattern_durations = journey_pattern_durations
            @scope = scope
          end
          attr_reader :journey_pattern_durations, :scope

          def find_all
            journey_pattern_durations.map do |attributes|
              JourneyPatternDuration.new(
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
            @journey_pattern_ids ||= journey_pattern_durations.map { |attributes| attributes['journey_pattern_id'] }
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
                    jsonb_build_object('time', avg_duration)
                  )
                ) AS durations
              FROM (
                SELECT
                  stop_area_pair,
                  journey_pattern_id AS journey_pattern_id,
                  avg(duration)::integer AS avg_duration
                FROM (
                  SELECT
                    departure.journey_pattern_id AS journey_pattern_id,
                    departure.vehicle_journey_id AS vehicle_journey_id,
                    (
                      SELECT 
                        extract(epoch from (arrival.arrival_time - departure.departure_time))
                      FROM (#{sub_query}) AS arrival
                      WHERE (arrival.position - departure.position) = 1
                      AND departure.vehicle_journey_id = arrival.vehicle_journey_id
                      AND departure.journey_pattern_id = arrival.journey_pattern_id
                      LIMIT 1
                    ) AS duration,
                    (
                      SELECT 
                        concat(departure.stop_area_id, '-', arrival.stop_area_id)
                      FROM (#{sub_query}) AS arrival 
                      WHERE (arrival.position - departure.position) = 1
                      AND departure.vehicle_journey_id = arrival.vehicle_journey_id
                      AND departure.journey_pattern_id = arrival.journey_pattern_id
                      LIMIT 1
                    ) AS stop_area_pair
                  FROM (#{sub_query}) AS departure
                ) AS avg_duration_table
                WHERE duration IS NOT NULL
                GROUP BY stop_area_pair, journey_pattern_id
              ) AS journey_pattern
              GROUP BY journey_pattern_id
            SQL

            PostgreSQLCursor::Cursor.new(query).to_a
          end
  
          def sub_query
            scope
              .joins(vehicle_journey_at_stops: { stop_point: :stop_area })
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
              public.stop_areas.id AS stop_area_id
            SQL
          end
        end

        class JourneyPatternDuration
          def initialize(attributes)
            attributes.each { |k, v| send "#{k}=", v if respond_to?(k) }
          end
          attr_accessor :journey_pattern

          def durations=(value)
            @durations = JSON.parse(value).reduce({}, :merge)
          end

          def durations
            @durations
          end
        end
      end

      def journey_patterns
        @journey_patterns ||= scope.journey_patterns
      end
    end
  end
end
