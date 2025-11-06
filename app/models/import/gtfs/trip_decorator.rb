class Import::Gtfs
  # Add helper methods on GTFS Trip
  class TripDecorator < SimpleDelegator
    def initialize(trip, lookup: nil, code_space: nil, default_time_zone: nil)
      super trip
      @lookup = lookup
      @code_space = code_space
      @default_time_zone = default_time_zone
    end

    attr_accessor :lookup, :code_space, :default_time_zone

    delegate :each, :length, :[], to: :stop_ids

    def route_signature
      @route_signature ||= [
        route_id,
        direction_id,
        stop_times_signature
      ].freeze
    end

    def stop_ids
      @stop_ids ||= stop_times.map(&:stop_id)
    end

    def journey_pattern_signature
      @journey_pattern_signature ||= [
        *route_signature,
        headsign,
        shape_id,
        *stop_ids
      ].freeze
    end

    def journey_pattern
      return unless lookup
      @journey_pattern ||= lookup.journey_patterns.find_by(signature: journey_pattern_signature)
    end

    def chouette_route_id
      journey_pattern&.route_id
    end

    def accessibility_assessment
      lookup.accessibility_assessments.find_by(wheelchair_accessible: wheelchair_accessible)
    end

    def service_facility_set
      lookup.service_facility_sets.find_by(bikes_allowed: bikes_allowed)
    end

    def vehicle_journey_at_stops
      [].tap do |vehicle_journey_at_stops|
        journey_pattern.stop_points.each_with_index do |stop_point, position|
          stop_time = stop_times[position]
          decorator = StopTimeDecorator.new(
            stop_time,
            stop_point: stop_point,
            starting_day_offset: starting_day_offset,
            default_time_zone: default_time_zone
          )
          vehicle_journey_at_stops << decorator.chouette_model
        end
      end
    end

    class StopTimeDecorator < SimpleDelegator
      def initialize(stop_time, stop_point: nil, starting_day_offset: nil, default_time_zone: nil)
        super stop_time

        @stop_point = stop_point
        @starting_day_offset = starting_day_offset
        @default_time_zone = default_time_zone
      end

      attr_accessor :starting_day_offset, :default_time_zone, :stop_point

      def departure_time_of_day
        time_of_day(departure_time)
      end

      def arrival_time_of_day
        time_of_day(arrival_time)
      end

      def earliest_departure_time_of_day
        time_of_day(start_pickup_drop_off_window)
      end

      def latest_arrival_time_of_day
        time_of_day(end_pickup_drop_off_window)
      end

      def time_of_day(raw_gtfs_time, offset: starting_day_offset)
        return unless raw_gtfs_time.present?

        # TODO
        # raise InvalidTimeError.new(gtfs_time) unless gtfs_time

        gtfs_time = GTFS::Time.parse(raw_gtfs_time).from_day_offset(offset)
        # TODO
        # raise InvalidTimeError.new(gtfs_time) unless t.present?

        TimeOfDay.create(gtfs_time, time_zone: default_time_zone).without_utc_offset
      end

      def stop_attributes
        {
          stop_point_id: stop_point.id,
          departure_time_of_day:,
          arrival_time_of_day:,
          earliest_departure_time_of_day:,
          latest_arrival_time_of_day:,
        }.compact
      end

      def chouette_model
        Chouette::VehicleJourneyAtStop.new(stop_attributes)
      end
    end

    def time_table_id
      return unless lookup
      lookup.time_tables.find_id(service_id, starting_day_offset: starting_day_offset)
    end

    def vehicle_journey_time_table_relationships
      unless time_table_id
        # TODO add error
        # errors << :time_table_not_found
        # create_message(
        #   {
        #     criticity: :warning,
        #     message_key: 'gtfs.trips.unknown_service_id',
        #     message_attributes: { service_id: trip.service_id },
        #     resource_attributes: {
        #       filename: "#{resource.name}.txt",
        #       line_number: resource.rows_count,
        #       column_number: 0
        #     }
        #   },
        #   resource: resource,
        #   commit: true
        # )
        return []
      end
      [ Chouette::TimeTablesVehicleJourney.new(time_table_id: time_table_id) ]
    end

    def vehicle_journey_attributes
      {
        route_id: chouette_route_id,
        journey_pattern: journey_pattern,
        published_journey_name: published_journey_name,
        published_journey_identifier: published_journey_identifier,
        codes: [ code ],
        accessibility_assessment: accessibility_assessment,
        service_facility_sets: [ service_facility_set ],
        vehicle_journey_at_stops: vehicle_journey_at_stops,
        vehicle_journey_time_table_relationships: vehicle_journey_time_table_relationships
      }
    end

    def chouette_model
      Chouette::VehicleJourney.new(vehicle_journey_attributes)
    end

    def code
      ReferentialCode.new(code_space: code_space, value: id)
    end

    def published_journey_name
      short_name.presence || id
    end

    def published_journey_identifier
      id
    end

    def starting_day_offset
      GtfsTime.parse(stop_times.first.departure_time || stop_times.first.start_pickup_drop_off_window).day_offset
    end

    def valid?
      stop_times.many?
    end

    private

    def stop_times_signature
      skip = true
      stop_times.reverse_each.filter_map do |stop_time|
        next if skip && stop_time.pickup_type.nil? && stop_time.drop_off_type.nil?

        skip = false
        flexible = stop_time.start_pickup_drop_off_window.present? && stop_time.end_pickup_drop_off_window.present?
        [
          stop_time.stop_id.presence || stop_time.location_group_id,
          stop_time.pickup_type || '0',
          stop_time.drop_off_type || '0',
          flexible
        ]
      end.to_a
    end
  end
end
