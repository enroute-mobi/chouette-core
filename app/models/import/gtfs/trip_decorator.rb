class Import::Gtfs
  # Add helper methods on GTFS Trip
  class TripDecorator < Import::Gtfs::Decorator
    attr_accessor :default_time_zone

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
      # TODO: manage more invalid cases ?
      return nil unless stop_times.many?

      @journey_pattern_signature ||= [
        *route_signature,
        headsign,
        shape_id,
        *stop_ids
      ].freeze
    end

    def journey_pattern
      return unless lookup && journey_pattern_signature
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
      unless journey_pattern
        errors.add :journey_pattern_invalid
        return []
      end

      unless stop_times.many?
        errors.add :stop_times_many_required
        return []
      end

      [].tap do |vehicle_journey_at_stops|
        previous = nil
        journey_pattern.stop_points.each_with_index do |stop_point, position|
          stop_time = stop_times[position]

          decorator = StopTimeDecorator.new(
            stop_time,
            stop_point: stop_point,
            starting_day_offset: starting_day_offset,
            default_time_zone: default_time_zone,
            previous: previous
          )

          unless decorator.valid?
            decorator.errors.each do |stop_time_error|
              stop_time_error.message_attributes[:trip_id] = id
              errors << stop_time_error
            end
            # TODO: we could skip the model creation
          end

          previous = decorator
          vehicle_journey_at_stops << decorator.chouette_model
        end
      end
    end

    class StopTimeDecorator < Import::Gtfs::Decorator
      attr_accessor :starting_day_offset, :default_time_zone, :stop_point, :previous

      def self.time_of_day(name, as:)
        define_method as do
          cached_value = instance_variable_get("@#{as}")
          return cached_value if cached_value

          value = try(name)
          return if value.blank?

          time_of_day(value).tap do |cached_value|
            instance_variable_set "@#{as}", cached_value
          end
        end
      end

      time_of_day :departure_time, as: :departure_time_of_day
      time_of_day :arrival_time, as: :arrival_time_of_day
      time_of_day :start_pickup_drop_off_window, as: :earliest_departure_time_of_day
      time_of_day :end_pickup_drop_off_window, as: :latest_arrival_time_of_day

      def time_of_day(raw_gtfs_time, offset: starting_day_offset)
        return if raw_gtfs_time.blank?

        gtfs_time = GTFS::Time.parse(raw_gtfs_time).from_day_offset(offset)
        return if gtfs_time.blank?

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

      def flexible?
        return false if [ try(:departure_time), try(:arrival_time) ].any?

        [
          try(:start_pickup_drop_off_window),
          try(:end_pickup_drop_off_window),
          try(:location_group_id),
          # try(:location_id)
        ].any?
      end

      def validate
        super

        unless flexible?
          if departure_time_of_day && arrival_time_of_day
            errors.add :arrival_after_departure if arrival_time_of_day > departure_time_of_day
          else
            errors.add :missing_departure_time if departure_time_of_day.nil?
            errors.add :missing_arrival_time if arrival_time_of_day.nil?
          end
        else
          if earliest_departure_time_of_day && latest_arrival_time_of_day
            errors.add :invalid_pickup_drop_off_window unless earliest_departure_time_of_day < latest_arrival_time_of_day
          else
            errors.add :missing_start_pickup_drop_off_window if earliest_departure_time_of_day.nil?
            errors.add :missing_end_pickup_drop_off_window if latest_arrival_time_of_day.nil?
          end
        end

        if arrival_time_of_day && previous&.departure_time_of_day
          errors.add :non_chronological if previous.departure_time_of_day > arrival_time_of_day
        end
      end

      def chouette_model
        Chouette::VehicleJourneyAtStop.new(stop_attributes)
      end
    end

    def time_table_id
      unless service_id
        errors.add :service_undefined
      end

      return unless lookup && starting_day_offset
      lookup.time_tables.find_id(service_id, starting_day_offset: starting_day_offset)
    end

    def vehicle_journey_time_table_relationships
      unless time_table_id
        errors.add :service_unknown, message_attributes: { service_id: service_id }
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
      @chouette_model ||= Chouette::VehicleJourney.new(vehicle_journey_attributes)
    end

    def validate
      super
      chouette_model
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
      return 0 if stop_times.empty?

      first_stop_time = stop_times.first
      first_time = first_stop_time.departure_time || first_stop_time.start_pickup_drop_off_window
      return 0 if first_time.blank?

      @starting_day_offset ||= GtfsTime.parse(first_time).day_offset
    end

    private

    def stop_times_signature
      skip = true
      stop_times.reverse_each.filter_map do |stop_time|
        # FIXME when pickup_type/drop_off_typeare not defined in the file, the signature is empty
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
