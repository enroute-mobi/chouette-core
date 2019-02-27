class Import::Gtfs < Import::Base
  include LocalImportSupport

  after_commit :update_main_resource_status, on:  [:create, :update]

  def launch_worker
    delay.import
  end

  def self.accepts_file?(file)
    Zip::File.open(file) do |zip_file|
      zip_file.glob('agency.txt').size == 1
    end
  rescue => e
    Rails.logger.debug "Error in testing GTFS file: #{e}"
    return false
  end

  def referential_metadata
    registration_numbers = source.routes.map(&:id)
    line_ids = line_referential.lines.where(registration_number: registration_numbers).pluck(:id)

    start_dates = []
    end_dates = []

    if source.entries.include?('calendar.txt')
      start_dates, end_dates = source.calendars.map { |c| [c.start_date, c.end_date] }.transpose
    end

    included_dates = []
    if source.entries.include?('calendar_dates.txt')
      included_dates = source.calendar_dates.select { |d| d.exception_type == "1" }.map(&:date)
    end

    min_date = Date.parse (start_dates + [included_dates.min]).compact.min
    min_date = [min_date, Date.current.beginning_of_year - PERIOD_EXTREME_VALUE].max

    max_date = Date.parse (end_dates + [included_dates.max]).compact.max
    max_date = [max_date, Date.current.end_of_year + PERIOD_EXTREME_VALUE].min

    ReferentialMetadata.new line_ids: line_ids, periodes: [min_date..max_date]
  end

  def source
    @source ||= ::GTFS::Source.build local_file.path, strict: false
  end

  def prepare_referential
    import_resources :agencies, :stops, :routes

    create_referential
    referential.switch
  end

  def import_without_status
    prepare_referential
    referential.pending!

    import_resources :calendars, :calendar_dates unless check_calendar_files_missing_and_create_message
    import_resources :trips, :stop_times
  end

  def import_agencies
    create_resource(:agencies).each(source.agencies) do |agency, resource|
      company = line_referential.companies.find_or_initialize_by(registration_number: agency.id)
      company.attributes = { name: agency.name }
      company.url = agency.url
      @default_time_zone ||= check_time_zone_or_create_message(agency.timezone, resource)
      company.time_zone = @default_time_zone

      save_model company, resource: resource
    end
  end

  def import_stops
    sorted_stops = source.stops.sort_by { |s| s.parent_station.present? ? 1 : 0 }
    create_resource(:stops).each(sorted_stops, slice: 100, transaction: true) do |stop, resource|
      stop_area = stop_area_referential.stop_areas.find_or_initialize_by(registration_number: stop.id)

      stop_area.name = stop.name
      stop_area.area_type = stop.location_type == '1' ? :zdlp : :zdep
      stop_area.latitude, stop_area.longitude = stop.lat, stop.lon
      stop_area.kind = :commercial
      stop_area.deleted_at = nil
      stop_area.confirmed_at = Time.now

      if stop.parent_station.present?
        if check_parent_is_valid_or_create_message(Chouette::StopArea, stop.parent_station, resource)
          parent = find_stop_parent_or_create_message(stop.name, stop.parent_station, resource)
          stop_area.parent = parent
          stop_area.time_zone = parent.try(:time_zone)
        end
      elsif stop.timezone.present?
        stop_area.time_zone = check_time_zone_or_create_message(stop.timezone, resource)
      else
        stop_area.time_zone = @default_time_zone
      end

      save_model stop_area, resource: resource
    end
  end

  def import_routes
    create_resource(:routes).each(source.routes, transaction: true) do |route, resource|
      if route.agency_id.present?
        next unless check_parent_is_valid_or_create_message(Chouette::Company, route.agency_id, resource)
      end
      line = line_referential.lines.find_or_initialize_by(registration_number: route.id)
      line.name = route.long_name.presence || route.short_name
      line.number = route.short_name
      line.published_name = route.long_name
      line.company = line_referential.companies.find_by(registration_number: route.agency_id) if route.agency_id.present?
      line.comment = route.desc

      line.transport_mode = case route.type
                            when '0', '5'
                              'tram'
                            when '1'
                              'metro'
                            when '2'
                              'rail'
                            when '3'
                              'bus'
                            when '7'
                              'funicular'
                            end

      # TODO: colors

      line.url = route.url

      save_model line, resource: resource
    end
  end

  def vehicle_journey_by_trip_id
    @vehicle_journey_by_trip_id ||= {}
  end

  def import_trips
    @trips = {}
    create_resource(:trips).each(source.trips, slice: 100, transaction: true) do |trip, resource|
      @trips[trip.id] = trip
    end
  end

  def import_stop_times
    # routes = Set.new
    prev_trip_id = nil
    to_be_saved = []
    create_resource(:stop_times).each(
      source.stop_times.group_by(&:trip_id),
      transaction: true,
      memory_profile: -> { "Import stop times from #{rows_count}" }
    ) do |row, resource|
      begin
        trip_id, stop_times = row
        to_be_saved = []
        prev_trip_id = trip_id

        trip = @trips[trip_id]
        line = line_referential.lines.find_by registration_number: trip.route_id
        route = referential.routes.build line: line
        route.wayback = (trip.direction_id == '0' ? :outbound : :inbound)
        name = route.published_name = trip.headsign.presence || trip.short_name.presence || route.wayback.to_s.capitalize
        route.name = name
        to_be_saved << route

        journey_pattern = route.journey_patterns.build name: name
        # to_be_saved << journey_pattern

        vehicle_journey = journey_pattern.vehicle_journeys.build route: route
        vehicle_journey.published_journey_name = trip.short_name.presence || trip.id

        to_be_saved << vehicle_journey

        time_table = referential.time_tables.find_by(id: time_tables_by_service_id[trip.service_id]) if time_tables_by_service_id[trip.service_id]
        if time_table
          vehicle_journey.time_tables << time_table
        else
          create_message(
            {
              criticity: :warning,
              message_key: 'gtfs.trips.unknown_service_id',
              message_attributes: { service_id: trip.service_id },
              resource_attributes: {
                filename: "#{resource.name}.txt",
                line_number: resource.rows_count,
                column_number: 0
              }
            },
            resource: resource,
            commit: true
          )
        end

        stop_times.sort_by! { |s| s.stop_sequence.to_i }

        raise InvalidTripTimesError unless consistent_stop_times(stop_times)

        stop_points = stop_times.each_with_index.map do |stop_time, i|
          [stop_time, import_stop_time(stop_time, route, resource, i==0)]
        end
        to_be_saved.each do |model|
          save_model model, resource: resource
        end
        stop_points.each do |stop_time, stop_point|
          next if stop_point.nil?
          add_stop_point stop_time, stop_point, journey_pattern, resource
        end
        save_model journey_pattern, resource: resource

      rescue Import::Gtfs::InvalidTripNonZeroFirstOffsetError, Import::Gtfs::InvalidTripTimesError => e
        message_key = e.is_a?(Import::Gtfs::InvalidTripNonZeroFirstOffsetError) ? 'trip_starting_with_non_zero_day_offset' : 'trip_with_inconsistent_stop_times'
        create_message(
          {
            criticity: :error,
            message_key: message_key,
            message_attributes: {
              trip_id: vehicle_journey.published_journey_name
            },
            resource_attributes: {
              filename: "#{resource.name}.txt",
              line_number: resource.rows_count,
              column_number: 0
            }
          },
          resource: resource, commit: true
        )
        @status = 'failed'
      rescue Import::Gtfs::InvalidTimeError => e
        create_message(
          {
            criticity: :error,
            message_key: 'invalid_stop_time',
            message_attributes: {
              time: e.time,
              trip_id: vehicle_journey.published_journey_name
            },
            resource_attributes: {
              filename: "#{resource.name}.txt",
              line_number: resource.rows_count,
              column_number: 0
            }
          },
          resource: resource, commit: true
        )
        @status = 'failed'
      end
    end
  end

  def consistent_stop_times(stop_times)
    times = stop_times.map{|s| [s.arrival_time, s.departure_time]}.flatten.compact
    times.inject(nil) do |prev, current|
      current = current.split(':').map &:to_i

      if prev
        return false if prev.first > current.first
        return false if prev.first == current.first && prev[1] > current[1]
        return false if prev.first == current.first && prev[1] == current[1] && prev[2] > current[2]
      end

      current
    end
    true
  end

  def import_stop_time(stop_time, route, resource, first)
    unless_parent_model_in_error(Chouette::StopArea, stop_time.stop_id, resource) do

      if first
        departure_time = GTFS::Time.parse(stop_time.departure_time)
        raise InvalidTimeError.new(stop_time.departure_time) unless departure_time.present?
        arrival_time = GTFS::Time.parse(stop_time.arrival_time)
        raise InvalidTimeError.new(stop_time.arrival_time) unless arrival_time.present?
        raise InvalidTripNonZeroFirstOffsetError unless departure_time.day_offset.zero? && arrival_time.day_offset.zero?
      end

      stop_area = stop_area_referential.stop_areas.find_by(registration_number: stop_time.stop_id)
      stop_point = route.stop_points.build stop_area: stop_area

      stop_point
    end
  end

  def add_stop_point(stop_time, stop_point, journey_pattern, resource)
    journey_pattern.stop_points << stop_point
    # JourneyPattern#vjas_add creates automaticaly VehicleJourneyAtStop
    vehicle_journey_at_stop = journey_pattern.vehicle_journey_at_stops.where(stop_point_id: stop_point.id).last
    departure_time = GTFS::Time.parse(stop_time.departure_time)
    raise InvalidTimeError.new(stop_time.departure_time) unless departure_time.present?

    arrival_time = GTFS::Time.parse(stop_time.arrival_time)
    raise InvalidTimeError.new(stop_time.arrival_time) unless arrival_time.present?

    if @previous_stop_sequence.nil? || stop_time.stop_sequence.to_i <= @previous_stop_sequence
      @vehicle_journey_at_stop_first_offset = departure_time.day_offset
    end

    vehicle_journey_at_stop.departure_time = departure_time.time(@default_time_zone)
    vehicle_journey_at_stop.arrival_time = arrival_time.time(@default_time_zone)
    vehicle_journey_at_stop.departure_day_offset = departure_time.day_offset - @vehicle_journey_at_stop_first_offset
    vehicle_journey_at_stop.arrival_day_offset = arrival_time.day_offset - @vehicle_journey_at_stop_first_offset

    # TODO: offset

    @previous_stop_sequence = stop_time.stop_sequence.to_i

    save_model vehicle_journey_at_stop, resource: resource
  end

  def time_tables_by_service_id
    @time_tables_by_service_id ||= {}
  end

  def import_calendars
    return unless source.entries.include?('calendar.txt')
    create_resource(:calendars).each(source.calendars, slice: 500, transaction: true) do |calendar, resource|
      time_table = referential.time_tables.build comment: "Calendar #{calendar.service_id}"
      Chouette::TimeTable.all_days.each do |day|
        time_table.send("#{day}=", calendar.send(day))
      end
      if calendar.start_date == calendar.end_date
        time_table.dates.build date: calendar.start_date, in_out: true
      else
        time_table.periods.build period_start: calendar.start_date, period_end: calendar.end_date
      end
      save_model time_table, resource: resource

      time_tables_by_service_id[calendar.service_id] = time_table.id
    end
  end

  def import_calendar_dates
    return unless source.entries.include?('calendar_dates.txt')

    create_resource(:calendar_dates).each(source.calendar_dates, slice: 500, transaction: true) do |calendar_date, resource|
      comment = "Calendar #{calendar_date.service_id}"
      unless_parent_model_in_error(Chouette::TimeTable, comment, resource) do
        time_table = referential.time_tables.where(id: time_tables_by_service_id[calendar_date.service_id]).last
        time_table ||= begin
          tt = referential.time_tables.build comment: comment
          save_model tt, resource: resource
          time_tables_by_service_id[calendar_date.service_id] = tt.id
          tt
        end

        date = time_table.dates.build date: Date.parse(calendar_date.date), in_out: calendar_date.exception_type == "1"
        save_model date, resource: resource
      end
    end
  end

  def find_stop_parent_or_create_message(stop_area_name, parent_station, resource)
    parent = stop_area_referential.stop_areas.find_by(registration_number: parent_station)
    unless parent
      create_message(
        {
          criticity: :error,
          message_key: :parent_not_found,
          message_attributes: {
            parent_name: parent_station,
            stop_area_name: stop_area_name,
          },
          resource_attributes: {
            filename: "#{resource.name}.txt",
            line_number: resource.rows_count,
            column_number: 0
          }
        },
        resource: resource, commit: true
      )
    end
    return parent
  end

  def check_time_zone_or_create_message(imported_time_zone, resource)
    return unless imported_time_zone
    time_zone = TZInfo::Timezone.all_country_zone_identifiers.select{|t| t==imported_time_zone}[0]
    unless time_zone
      create_message(
        {
          criticity: :error,
          message_key: :invalid_time_zone,
          message_attributes: {
            time_zone: imported_time_zone,
          },
          resource_attributes: {
            filename: "#{resource.name}.txt",
            line_number: resource.rows_count,
            column_number: 0
          }
        },
        resource: resource, commit: true
      )
    end
    return time_zone
  end

  def check_calendar_files_missing_and_create_message
    if source.entries.include?('calendar.txt') || source.entries.include?('calendar_dates.txt')
      return false
    end

    create_message(
      {
        criticity: :error,
        message_key: 'missing_calendar_or_calendar_dates_in_zip_file',
      },
      resource: resource, commit: true
    )
    @status = 'failed'
  end

  class InvalidTripNonZeroFirstOffsetError < StandardError; end
  class InvalidTripTimesError < StandardError; end
  class InvalidTimeError < StandardError
    attr_reader :time

    def initialize(time)
      @time = time
    end
  end
end
