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
          arrival = Step.for(arrival, duration: duration, validity_period: validity_period)

          destinations << Destination.new(departure, arrival)
        end

        class Destination
          def initialize(departure, arrival, validity_period: ValidityPeriod.new)
            self.departure = departure
            self.arrival = arrival
          end

          attr_accessor :departure, :arrival

          def extend(journey, validity_period: nil)
            return nil unless departure == journey.last

            journey.extend arrival, validity_period: validity_period
          end
        end

        def extend(journeys, validity_period: nil)
          extended_journeys = []

          journeys.each do |journey|
            destinations.each do |destination|
              extended_journey = destination.extend journey, validity_period: validity_period
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

        def extend(journeys, validity_period: nil)
          Extend.new(self, journeys, validity_period: validity_period).extend
        end

        delegate :connection, to: :stop_areas
        delegate :select_rows, to: :connection

        class Extend < SimpleDelegator
          def initialize(extender, journeys, validity_period: nil)
            super extender
            @journeys = journeys
            @validity_period = validity_period
          end

          attr_reader :journeys, :validity_period

          def extend
            return [] if extendable_journeys.empty?

            next_steps.each do |origin_step_id, next_step|
              extendable_journeys_by_last_id[origin_step_id].each do |journey|
                extended_journeys << journey.extend(next_step, validity_period: validity_period)
              end
            end

            extended_journeys
          end

          def next_steps
            select_rows(query).map do |step_id, stop_area_id, stop_area_latitude, stop_area_longitude, distance|
              step = Step::StopArea.new(
                stop_area_id: stop_area_id,
                position: Geo::Position.new(latitude: stop_area_latitude, longitude: stop_area_longitude),
                duration: distance / walk_speed,
                created_by: self.class
              )
              [step_id, step]
            end
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
            @extendable_journeys_by_last_id ||= extendable_journeys_by_last.transform_keys(&:id)
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

      class ByVehicleJourneyStopAreas
        def initialize(time_tables:, vehicle_journeys: nil, vehicle_journeys_at_stops: nil, maximum_time_of_day: nil)
          @vehicle_journeys = vehicle_journeys
          @vehicle_journey_at_stops = vehicle_journey_at_stops

          unless @vehicle_journey_at_stops || @vehicle_journeys
            raise ArgumentError, 'Requires vehicle_journey_at_stops or vehicle_journeys'
          end

          @time_tables = TimeTables.new time_tables
          @maximum_time_of_day = maximum_time_of_day
        end

        attr_accessor :vehicle_journeys, :time_tables, :maximum_time_of_day

        def extend(journeys, validity_period: nil)
          Extend.new(self, journeys, validity_period: validity_period).extend
        end

        def connection
          Chouette::VehicleJourneyAtStop.connection
        end
        delegate :select_rows, to: :connection

        def vehicle_journey_at_stops
          @vehicle_journey_at_stops ||= Chouette::VehicleJourneyAtStop.where(vehicle_journey_id: vehicle_journeys)
        end

        class TimeTables
          def initialize(time_tables)
            @time_tables = time_tables
          end

          attr_accessor :time_tables

          def time_table_days_bits
            @time_table_days_bits ||= {}
          end

          def load(time_table_ids)
            time_table_ids = Set.new(time_table_ids - time_table_days_bits.keys)

            time_tables.where(id: time_table_ids).includes(:dates, :periods).find_each do |time_table|
              days_bit = time_table.to_days_bit
              time_table_days_bits[time_table.id] = days_bit if days_bit
            end
          end

          def days_bit(time_table_ids)
            Cuckoo::DaysBit.merge(*time_table_days_bits.values_at(*time_table_ids).compact)
          end

          def validity_period(time_table_ids)
            ValidityPeriod.from_daysbit days_bit(time_table_ids)
          end
        end

        class Extend < SimpleDelegator
          def initialize(extender, journeys, validity_period:)
            super extender
            @journeys = journeys
            @validity_period = validity_period
          end

          attr_reader :journeys, :validity_period

          def extend
            return [] if extendable_journeys.empty?

            next_steps.each do |journey_id, steps|
              journey = extendable_journey(journey_id)
              steps.each do |next_step|
                extended_journey = journey.extend(next_step, validity_period: validity_period)

                extended_journeys << extended_journey unless extended_journey.validity_period.empty?
              end
            end

            extended_journeys
          end

          def next_steps
            next_steps = Hash.new { |h, k| h[k] = [] }

            time_tables.load time_table_ids

            rows.each do |row|
              step = row.create_step
              step.validity_period = time_tables.validity_period(row.time_table_ids)

              next_steps[row.journey_id] << step
            end

            next_steps
          end

          def time_table_ids
            rows.flat_map(&:time_table_ids).uniq
          end

          def rows
            @rows ||= select_rows(query).map do |journey_id, stop_area_id, duration, stop_area_latitude, stop_area_longitude, time_table_ids|
              Row.new(journey_id, stop_area_id, duration, stop_area_latitude, stop_area_longitude, time_table_ids)
            end
          end

          class Row
            attr_accessor :journey_id, :stop_area_id, :duration, :stop_area_latitude, :stop_area_longitude,
                          :time_table_ids

            def initialize(journey_id, stop_area_id, duration, stop_area_latitude, stop_area_longitude, time_table_ids)
              @journey_id = journey_id
              @stop_area_id = stop_area_id
              @duration = duration
              @stop_area_latitude = stop_area_latitude
              @stop_area_longitude = stop_area_longitude
              @time_table_ids = time_table_ids.delete('{}').split(',').map(&:to_i)
            end

            def position
              Geo::Position.new(latitude: stop_area_latitude, longitude: stop_area_longitude)
            end

            def create_step
              Step::StopArea.new(
                stop_area_id: stop_area_id,
                position: position,
                duration: duration.to_i
              )
            end
          end

          def extended_journeys
            @extended_journeys ||= []
          end

          def extendable_journeys
            journeys.select do |journey|
              # TODO: we could support a mode without time reference
              journey.time_reference? &&
                journey.last.respond_to?(:stop_area_id)
              # TODO: seems wrong: journey.last.created_by != self.class
            end
          end

          def extendable_journeys_by_id
            @extendable_journeys_by_id ||= extendable_journeys.index_by(&:id)
          end

          def extendable_journey(id)
            extendable_journeys_by_id[id]
          end

          def extendable_steps_sql
            extendable_journeys.map do |journey|
              step = journey.last
              "('#{journey.id}',#{step.stop_area_id},'#{journey.time_of_day.to_hms}'::time,#{journey.time_of_day.day_offset})"
            end.join(',')
          end

          def maximum_time_of_day_sql
            return nil unless maximum_time_of_day

            "where arrival_time < '#{maximum_time_of_day.to_hms}' AND arrival_day_offset <= #{maximum_time_of_day.day_offset}"
          end

          def query
            # TODO: Ensure that duration computation is correct
            # TODO: we could exclude the timetables which are not longer the Planner Validity Period
            <<~SQL
              select departure_stops.step_id, stop_points.stop_area_id,
                     (EXTRACT(EPOCH FROM arrival_time) + arrival_day_offset * 86400) - (EXTRACT(EPOCH FROM departure_stops.departure_time) + departure_stops.departure_day_offset * 86400) as duration,
                     public.stop_areas.latitude, public.stop_areas.longitude, time_table_ids
              from (#{vehicle_journey_at_stops.to_sql}) as scoped_vehicle_journey_at_stops
              inner join stop_points ON stop_points.id = scoped_vehicle_journey_at_stops.stop_point_id
              inner join public.stop_areas ON stop_points.stop_area_id = public.stop_areas.id
                AND public.stop_areas.latitude IS NOT NULL AND public.stop_areas.longitude IS NOT NULL

              join (
                select
                  vehicle_journey_id, position, step_id, departure_time, departure_day_offset, array_agg(time_table_id) as time_table_ids
                from (
                  select
                    vehicle_journey_at_stops.vehicle_journey_id as vehicle_journey_id,
                    stop_points.position as position,
                    steps.id as step_id, steps.departure_time, steps.departure_day_offset,
                    time_tables_vehicle_journeys.time_table_id as time_table_id
                  from vehicle_journey_at_stops
                  inner join stop_points
                    ON stop_points.id = vehicle_journey_at_stops.stop_point_id
                  inner join time_tables_vehicle_journeys
                    ON time_tables_vehicle_journeys.vehicle_journey_id = vehicle_journey_at_stops.vehicle_journey_id
                  join (
                    select *
                    from ( values #{extendable_steps_sql} ) as t (id, stop_area_id, departure_time, departure_day_offset)
                  ) steps
                  ON stop_points.stop_area_id = steps.stop_area_id
                    AND vehicle_journey_at_stops.departure_time > steps.departure_time
                    AND vehicle_journey_at_stops.departure_day_offset >= steps.departure_day_offset
                ) departure_stops_with_single_timetable
                group by vehicle_journey_id, position, step_id, departure_time, departure_day_offset
              ) departure_stops
              on scoped_vehicle_journey_at_stops.vehicle_journey_id = departure_stops.vehicle_journey_id
                  AND stop_points.position > departure_stops.position
              #{maximum_time_of_day_sql}
            SQL
          end
        end
      end

      # TODO: WIP, more complex than expected and not mandatory
      class ConnectedStopAreas
        attr_accessor :connection_links

        def initialize(connection_links)
          @connection_links = connection_links
        end

        attr_reader :connection_links

        def extend(journeys, validity_period: nil)
          Extend.new(self, journeys, validity_period: validity_period).extend
        end

        delegate :connection, to: :connection_links
        delegate :select_rows, to: :connection

        class Extend < SimpleDelegator
          def initialize(extender, journeys, validity_period: nil)
            super extender
            @journeys = journeys
            @validity_period = validity_period
          end

          attr_reader :journeys, :validity_period

          def extend
            next_steps.each do |origin_step_id, next_step|
              extendable_journeys_by_last_id[origin_step_id].each do |journey|
                extended_journeys << journey.extend(next_step, validity_period: validity_period)
              end
            end

            extended_journeys
          end

          def next_steps
            select_rows(query).map do |step_id, stop_area_id, stop_area_latitude, stop_area_longitude, duration|
              step = Step::StopArea.new(
                stop_area_id: stop_area_id,
                position: Geo::Position.new(latitude: stop_area_latitude, longitude: stop_area_longitude),
                duration: duration.to_i
              )
              [step_id, step]
            end.to_h
          end

          def extended_journeys
            @extended_journeys ||= []
          end

          def extendable_journeys
            journeys
              .select { |journey| journey.last.respond_to?(:stop_area_id) }
              .reject { |journey| journey.last.created_by == self.class }
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
            extendable_steps.map { |s| "('#{s.id}',#{s.stop_area_id})" }.join(',')
          end

          def query
            # TODO: make union of both_way and one_way ConnectionLinks
            <<~SQL
              select steps.id, scoped_connection_links.arrival_id,
                     stop_areas.latitude, stop_areas.longitude, scoped_connection_links.default_duration
              from (#{connection_links.to_sql}) as scoped_connection_links
              join (
                select *
                from ( values #{extendable_steps_sql} ) as t (id, stop_area_id)
              ) steps
              on scoped_connection_links.departure_id == steps.stop_area_id
              join public.stop_areas on scoped_connection_links.arrival_id == public.stop_areas.id
            SQL
          end
        end
      end
    end
  end
end
