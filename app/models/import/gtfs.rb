class Import::Gtfs < Import::Base # rubocop:disable Metrics/ClassLength
  include LocalImportSupport

  after_commit :update_main_resource_status, on:  [:create, :update]

  def operation_progress_weight(operation_name)
    operation_name.to_sym == :stop_times ? 90 : 10.0/10
  end

  def operations_progress_total_weight
    100
  end

  def self.accepts_file?(file)
    Zip::File.open(file) do |zip_file|
      zip_file.glob('agency.txt').size == 1
    end
  rescue => e
    Chouette::Safe.capture "Error in testing GTFS file: #{file}", e
    return false
  end

  def line_provider
    workbench.default_line_provider
  end

  def lines
    line_referential.lines.by_provider(line_provider)
  end

  def companies
    line_referential.companies.by_provider(line_provider)
  end

  def referential_metadata
    registration_numbers = source.routes.map(&:id)
    line_ids = lines.where(registration_number: registration_numbers).pluck(:id)

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
    import_resources :agencies, :stops, :routes, :shapes, :fare_products, :fare_validities

    create_referential
    referential.switch
  end

  def import_without_status
    prepare_referential

    check_calendar_files_missing_and_create_message || import_resources(:services)

    import_resources :transfers if source.entries.include?('transfers.txt')

    import_resources :stop_times

    import_resources :attributions

    calculate_route_costs
  end

  def calculate_route_costs
    RouteCalculateCostsService.new(referential, update_journey_patterns: true).update_all
  end

  def import_attributions
    Attributions.new(self).import!
  end

  class Attributions

    def initialize(import)
      @import = import
    end
    attr_reader :import

    delegate :source, :workbench, :referential, :code_space, to: :import

    def import!
      source.attributions.each do |attribution|
        decorator = Decorator.for(attribution).new(
          attribution,
          referential: referential,
          code_space: code_space,
          workbench: workbench
        ) rescue nil

        decorator.attribute! if decorator
      end
    end

    class Decorator < SimpleDelegator

      def initialize(attribution, referential: nil, code_space: nil, workbench: nil)
        super attribution
        @referential = referential
        @code_space = code_space
        @workbench = workbench
      end
      attr_accessor :referential, :code_space, :workbench

      def self.for(gtfs_attribution)
        [ TripOperatorDecorator ].find do |decorator_class|
          decorator_class.matches?(gtfs_attribution)
        end
      end
    end

    class TripOperatorDecorator < Decorator
      def self.matches?(gtfs_attribution)
        gtfs_attribution.operator? && gtfs_attribution.trip_id && gtfs_attribution.organization_name
      end

      def vehicle_journey
        referential.vehicle_journeys.by_code(code_space, trip_id).first
      end

      def company
        unless (companies = workbench.companies.where(name: organization_name)).many?
          companies.first
        end
      end

      def attribute!
        return if vehicle_journey.blank? || company.blank?

        vehicle_journey.update company: company
      end
    end
  end

  def import_agencies
    resource = create_resource(:agencies)
    resource.rows_count = source.agencies.count
    resource.save!

    Agencies.new(WithResource.new(self, resource)).import!
  end

  # Try to hide the resource management for modern code
  #
  # Provides #save_model and #create_message method without resource concept/argument
  class WithResource < SimpleDelegator

    def initialize(import, resource)
      super import

      @import, @resource = import, resource
    end

    attr_reader :import, :resource

    def save_model(model)
      import.save_model model, resource: resource
    end

    def create_message(attributes)
      attributes[:resource_attributes] = {
        filename: "#{resource.name}.txt",
        line_number: resource.rows_count
      }
      import.create_message attributes, resource: resource, commit: true
    end

  end

  class Agencies

    def initialize(import)
      @import = import
    end

    attr_reader :import
    delegate :source, :companies, :create_message, :save_model,
             :default_company=, :default_time_zone, :default_time_zone=, to: :import

    def import!
      source.agencies.each do |agency|
        decorated_agency = Decorator.new(agency, default_time_zone: default_time_zone, mandatory_id: !default_agency?)

        unless decorated_agency.valid?
          decorated_agency.errors.each { |error| create_message error }
          next
        end

        # TODO use code
        company = companies.find_or_initialize_by registration_number: decorated_agency.code
        company.attributes = decorated_agency.company_attributes

        save_model company

        self.default_company = company if default_agency?
        self.default_time_zone = decorated_agency.time_zone # TODO Company should support real TimeZone object ..
      end
    end

    def default_agency?
      @default_agency ||= source.agencies.one?
    end

    class Decorator < SimpleDelegator

      def initialize(agency, default_time_zone: nil, mandatory_id: false)
        super agency
        @agency, @default_time_zone, @mandatory_id = agency, default_time_zone, mandatory_id
      end

      attr_reader :agency
      attr_accessor :default_time_zone, :mandatory_id
      alias mandatory_id? mandatory_id

      def code
        id.presence || default_code
      end

      def default_code
        name.presence && name.parameterize
      end

      def time_zone
        @time_zone ||= ActiveSupport::TimeZone[timezone] if timezone
      end

      def time_zone_name
        time_zone.tzinfo.name if time_zone
      end

      def company_attributes
        {
          name: name,
          default_language: lang,
          default_contact_url: url,
          default_contact_phone: phone,
          time_zone: time_zone_name # TODO Company should support real TimeZone object ..
        }
      end

      def errors
        @errors ||= []
      end

      def valid?
        errors.clear

        if mandatory_id? && id.blank?
          errors << {
            criticity: :error,
            message_key: 'gtfs.agencies.missing_agency_id'
          }
        end

        unless time_zone
          errors << {
            criticity: :error,
            message_key: :invalid_time_zone,
            message_attributes: {
              time_zone: timezone,
            }
          }
        end

        if default_time_zone && time_zone != default_time_zone
          errors << {
            criticity: :error,
            message_key: 'gtfs.agencies.default_time_zone'
          }
        end

        errors.empty?
      end

    end

  end

  attr_accessor :default_time_zone, :default_company

  def import_stops
    sorted_stops = source.stops.sort_by { |s| s.parent_station.present? ? 1 : 0 }
    @stop_areas_id_by_registration_number = {}

    CustomFieldsSupport.within_workgroup(workbench.workgroup) do
      create_resource(:stops).each(sorted_stops, slice: 100, transaction: true) do |stop, resource|
        stop_area = stop_areas.find_or_initialize_by(registration_number: stop.id)

        stop_area.name = stop.name
        stop_area.public_code = stop.platform_code
        stop_area.stop_area_provider = stop_area_provider
        stop_area.area_type = stop.location_type == '1' ? :zdlp : :zdep
        stop_area.latitude = stop.lat.presence && stop.lat.to_f
        stop_area.longitude = stop.lon.presence && stop.lon.to_f
        stop_area.kind = :commercial
        stop_area.deleted_at = nil
        stop_area.confirmed_at ||= Time.now
        stop_area.comment = stop.desc
        stop_area.fare_code = stop.zone_id if stop.zone_id.present?

        if stop.wheelchair_boarding
          case stop.wheelchair_boarding
          when '0'
            # Keep unchange a current mobility_impaired_accessibility value
            stop_area.mobility_impaired_accessibility ||= 'unknown'
          when '1'
            stop_area.mobility_impaired_accessibility = 'yes'
          when '2'
            stop_area.mobility_impaired_accessibility = 'no'
          end
        end

        stop_area.codes.find_or_initialize_by(code_space: public_code_space).tap do |code|
          code.value = stop.code
          code.save unless stop_area.new_record?
        end if stop.code.present?

        if stop.parent_station.present?
          if check_parent_is_valid_or_create_message(Chouette::StopArea, stop.parent_station, resource)
            parent = find_stop_parent_or_create_message(stop.name, stop.parent_station, resource)
            stop_area.parent = parent
            stop_area.time_zone = parent.try(:time_zone)
          end
        elsif stop.timezone.present?
          time_zone = ActiveSupport::TimeZone[stop.timezone]
          if time_zone
            stop_area.time_zone = time_zone.tzinfo.name
          else
            create_message(
              {
                criticity: :error,
                message_key: :invalid_time_zone,
                message_attributes: {
                  time_zone: stop.timezone,
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
        else
          stop_area.time_zone = default_time_zone&.tzinfo&.name # TODO StopArea should support real TimeZone object ..
        end

        save_model stop_area, resource: resource
        @stop_areas_id_by_registration_number[stop_area.registration_number] = stop_area.id
      end
    end

    if disable_missing_resources?
      unknown_stop_areas = stop_area_provider.stop_areas.where.not(registration_number: @stop_areas_id_by_registration_number.keys)
      unknown_stop_areas.update_all deleted_at: Time.current
    end
  end

  def lines_by_registration_number(registration_number)
    @lines_by_registration_number ||= {}
    line = lines.includes(:company).find_or_initialize_by(registration_number: registration_number)
    line.line_provider = line_provider
    @lines_by_registration_number[registration_number] ||= line
  end

  def import_routes
    @lines_by_registration_number = {}

    CustomFieldsSupport.within_workgroup(workbench.workgroup) do
      create_resource(:routes).each(source.routes, transaction: true) do |route, resource|
        if route.agency_id.present?
          next unless check_parent_is_valid_or_create_message(Chouette::Company, route.agency_id, resource)
        end
        line = lines_by_registration_number(route.id)
        line.name = route.long_name.presence || route.short_name
        line.number = route.short_name
        line.published_name = route.long_name

        if route.agency_id.blank? && default_company
          line.company = default_company
        else
          unless route.agency_id == line.company&.registration_number
            line.company = companies.find_by(registration_number: route.agency_id) if route.agency_id.present?
          end
        end

        line.comment = route.desc

        transport_mode, transport_submode =
          case route.type
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
          when '204'
            [ 'coach', 'regionalCoach' ]
          when '200'
            'coach'
          when '713'
            [ 'bus', 'schoolAndPublicServiceBus' ]
          end

        transport_submode ||= 'undefined'

        if transport_mode
          line.transport_mode = transport_mode
          line.transport_submode = transport_submode
        end

        # White is the default color in the gtfs spec
        line.color = parse_color(route.color) if route.color
        # Black is the default text color in the gtfs spec
        line.text_color = parse_color(route.text_color) if route.text_color

        line.url = route.url

        save_model line, resource: resource
      end
    end

    if disable_missing_resources?
      unknown_lines = line_provider.lines.where.not(registration_number: @lines_by_registration_number.keys)
      unknown_lines.update_all deactivated: true
    end
  end

  def vehicle_journey_by_trip_id
    @vehicle_journey_by_trip_id ||= {}
  end

  def import_transfers
    @trips = {}
    create_resource(:transfers).each(source.transfers, slice: 100, transaction: true) do |transfer, resource|
      next unless transfer.type == '2'
      from_id = @stop_areas_id_by_registration_number[transfer.from_stop_id]
      unless from_id
        create_message(
          {
            criticity: :error,
            message_key: 'gtfs.transfers.missing_stop_id',
            message_attributes: { stop_id: transfer.from_stop_id },
            resource_attributes: {
              filename: "#{resource.name}.txt",
              line_number: resource.rows_count,
              column_number: 0
            }
          },
          resource: resource,
          commit: true
        )
        next
      end
      to_id = @stop_areas_id_by_registration_number[transfer.to_stop_id]
      unless to_id
        create_message(
          {
            criticity: :error,
            message_key: 'gtfs.transfers.missing_stop_id',
            message_attributes: { stop_id: transfer.to_stop_id },
            resource_attributes: {
              filename: "#{resource.name}.txt",
              line_number: resource.rows_count,
              column_number: 0
            }
          },
          resource: resource,
          commit: true
        )
        next
      end
      if from_id == to_id
        create_message(
          {
            criticity: :warning,
            message_key: 'gtfs.transfers.same_arrival_and_departure',
            resource_attributes: {
              filename: "#{resource.name}.txt",
              line_number: resource.rows_count,
              column_number: 0
            }
          },
          resource: resource,
          commit: true
        )
        next
      end

      connection = connection_links.find_by(departure_id: from_id, arrival_id: to_id, both_ways: true)
      connection ||= connection_links.find_or_initialize_by(departure_id: to_id, arrival_id: from_id, both_ways: true)
      if transfer.min_transfer_time.present?
        connection.default_duration = transfer.min_transfer_time
        if [:frequent_traveller_duration, :occasional_traveller_duration,
          :mobility_restricted_traveller_duration].any? { |k| connection.send(k).present? }
          create_message(
            {
              criticity: :warning,
              message_key: 'gtfs.transfers.replacing_duration',
              message_attributes: { from_id: transfer.from_stop_id, to_id: transfer.to_stop_id },
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
      end
      save_model connection, resource: resource
    end
  end

  def process_trip(resource, trip, stop_times)
    begin
      raise InvalidTripSingleStopTime unless stop_times.many?

      journey_pattern = find_or_create_journey_pattern(resource, trip, stop_times)
      vehicle_journey = journey_pattern.vehicle_journeys.build route: journey_pattern.route, skip_custom_fields_initialization: true
      vehicle_journey.published_journey_name = trip.short_name.presence || trip.id
      vehicle_journey.codes.build code_space: code_space, value: trip.id

      ApplicationModel.skipping_objectid_uniqueness do
        save_model vehicle_journey, resource: resource
      end

      starting_day_offset = GTFSTime.parse(stop_times.first.departure_time).day_offset
      time_table_id = handle_timetable_with_offset(resource, trip, starting_day_offset)

      if time_table_id
        Chouette::TimeTablesVehicleJourney.create!(time_table_id: time_table_id, vehicle_journey_id: vehicle_journey.id)
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

      Chouette::VehicleJourneyAtStop.bulk_insert do |worker|
        journey_pattern.stop_points.each_with_index do |stop_point, i|
          add_stop_point stop_times[i], i, starting_day_offset, stop_point, vehicle_journey, worker
        end
      end

      save_model journey_pattern, resource: resource
    rescue Import::Gtfs::InvalidTripTimesError, Import::Gtfs::InvalidTripSingleStopTime, Import::Gtfs::InvalidStopAreaError => e
      message_key = case e
        when Import::Gtfs::InvalidTripTimesError
          'trip_with_inconsistent_stop_times'
        when Import::Gtfs::InvalidTripSingleStopTime
          'trip_with_single_stop_time'
        when Import::Gtfs::InvalidStopAreaError
          'no_specified_stop'
        end
      create_message(
        {
          criticity: :error,
          message_key: message_key,
          message_attributes: {
            trip_id: trip.id
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

  def handle_timetable_with_offset(resource, trip, offset)
    return nil if time_tables_by_service_id[trip.service_id].nil?
    return time_tables_by_service_id[trip.service_id][offset] if time_tables_by_service_id[trip.service_id][offset]

    original_tt_id = time_tables_by_service_id[trip.service_id].first
    original_tt = referential.time_tables.find(original_tt_id)

    tmp_tt = original_tt.to_timetable
    tmp_tt.shift offset

    shifted_tt = referential.time_tables.build comment: trip.service_id
    shifted_tt.apply(tmp_tt)
    shifted_tt.shortcuts_update
    shifted_tt.skip_save_shortcuts = true
    save_model shifted_tt, resource: resource

    time_tables_by_service_id[trip.service_id][offset] = shifted_tt.id
  end

  def journey_pattern_ids
    @journey_pattern_ids ||= {}
  end

  def trip_signature(trip, stop_times)
    [
      trip.route_id,
      trip.direction_id,
      trip.headsign,
      trip.short_name,
      trip.shape_id,
    ] + stop_times.map(&:stop_id)
  end

  def find_or_create_journey_pattern(resource, trip, stop_times)
    journey_pattern_id = journey_pattern_ids[trip_signature(trip, stop_times)]
    return Chouette::JourneyPattern.find(journey_pattern_id) if journey_pattern_id
    stop_points = []

    line = lines.find_by registration_number: trip.route_id

    route = referential.routes.build line: line
    route.wayback = (trip.direction_id == '0' ? :outbound : :inbound)
    route.name = trip.headsign.presence || trip.short_name.presence || route.wayback.to_s.capitalize

    journey_pattern = route.journey_patterns.build skip_custom_fields_initialization: true
    journey_pattern.name = route.name
    journey_pattern.published_name = trip.headsign

    if trip.shape_id
      shape = shape_provider.shapes.by_code(code_space, trip.shape_id).first
      journey_pattern.shape = shape
    end

    raise InvalidTripTimesError unless consistent_stop_times(stop_times)
    stop_points_with_times = stop_times.each_with_index.map do |stop_time, i|
      [stop_time, import_stop_time(stop_time, journey_pattern.route, resource, i)]
    end
    ApplicationModel.skipping_objectid_uniqueness do
        save_model route, resource: resource
    end

    stop_points = stop_points_with_times.map do |s|
      if stop_point = s.last
        @objectid_formatter ||= Chouette::ObjectidFormatter.for_objectid_provider(StopAreaReferential, id: referential.stop_area_referential_id)
        stop_point[:route_id] = journey_pattern.route.id
        stop_point[:objectid] = @objectid_formatter.objectid(stop_point)
        stop_point
      end
    end

    worker = nil
    if stop_points.compact.present?
      Chouette::StopPoint.bulk_insert(:route_id, :objectid, :stop_area_id, :position, return_primary_keys: true) do |w|
        stop_points.compact.each { |s| w.add(s.attributes) }
        worker = w
      end
      stop_points = Chouette::StopPoint.find worker.result_sets.last.rows
    else
      stop_points = []
    end

    Chouette::JourneyPatternsStopPoint.bulk_insert do |w|
      stop_points.each do |stop_point|
        w.add journey_pattern_id: journey_pattern.id, stop_point_id: stop_point.id
      end
    end

    journey_pattern.departure_stop_point_id = stop_points.first.id
    journey_pattern.arrival_stop_point_id = stop_points.last.id

    ApplicationModel.skipping_objectid_uniqueness do
        save_model journey_pattern, resource: resource
    end

    journey_pattern_ids[trip_signature(trip, stop_times)] = journey_pattern.id
    journey_pattern
  end

  def import_stop_times
    CustomFieldsSupport.within_workgroup(workbench.workgroup) do
      resource = create_resource(:stop_times)
      source.to_enum(:each_trip_with_stop_times).each_slice(100) do |slice|
        Chouette::VehicleJourney.transaction do
          slice.each do |trip, stop_times|
            process_trip(resource, trip, stop_times)
          end
        end
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

  def import_stop_time(stop_time, route, resource, position)
    unless_parent_model_in_error(Chouette::StopArea, stop_time.stop_id, resource) do

      if position == 0
        departure_time = GTFSTime.parse(stop_time.departure_time)
        raise InvalidTimeError.new(stop_time.departure_time) unless departure_time.present?
      end

      stop_area_id = @stop_areas_id_by_registration_number[stop_time.stop_id]
      raise InvalidStopAreaError unless stop_area_id.present?

      Chouette::StopPoint.new(stop_area_id: stop_area_id, position: position )
    end
  end

  def add_stop_point(stop_time, position, starting_day_offset, stop_point, vehicle_journey, worker)
    # JourneyPattern#vjas_add creates automaticaly VehicleJourneyAtStop
    vehicle_journey_at_stop = vehicle_journey.vehicle_journey_at_stops.build(stop_point_id: stop_point.id)

    departure_time_of_day = time_of_day stop_time.departure_time, starting_day_offset
    vehicle_journey_at_stop.departure_time_of_day = departure_time_of_day

    if position == 0
      vehicle_journey_at_stop.arrival_time_of_day = departure_time_of_day
    else
      vehicle_journey_at_stop.arrival_time_of_day = time_of_day stop_time.arrival_time, starting_day_offset
    end

    worker.add vehicle_journey_at_stop.attributes
  end

  def time_of_day gtfs_time, offset
    t = GTFS::Time.parse(gtfs_time).from_day_offset(offset)
    raise InvalidTimeError.new(gtfs_time) unless t.present?

    TimeOfDay.create(t, time_zone: default_time_zone).without_utc_offset
  end

  # for each service_id we store an array of TimeTables for each needed starting day offset
  def time_tables_by_service_id
    @time_tables_by_service_id ||= {}
  end

  def import_calendars
    return unless source.entries.include?('calendar.txt')

    Chouette::TimeTable.skipping_objectid_uniqueness do
      create_resource(:calendars).each(source.calendars, slice: 500, transaction: true) do |calendar, resource|
        time_table = referential.time_tables.build comment: calendar.service_id
        Chouette::TimeTable.all_days.each do |day|
          time_table.send("#{day}=", calendar.send(day))
        end
        if calendar.start_date == calendar.end_date
          time_table.dates.build date: calendar.start_date, in_out: true
        else
          time_table.periods.build period_start: calendar.start_date, period_end: calendar.end_date
        end
        time_table.shortcuts_update
        time_table.skip_save_shortcuts = true
        save_model time_table, resource: resource

        time_tables_by_service_id[calendar.service_id] = [time_table.id]
      end
    end
  end

  def import_calendar_dates
    return unless source.entries.include?('calendar_dates.txt')

    positions = Hash.new{ |h, k| h[k] = 0 }
    Chouette::TimeTableDate.bulk_insert do |worker|
      create_resource(:calendar_dates).each(source.calendar_dates, slice: 500, transaction: true) do |calendar_date, resource|
        comment = "#{calendar_date.service_id}"
        unless_parent_model_in_error(Chouette::TimeTable, comment, resource) do
          time_table_id = time_tables_by_service_id[calendar_date.service_id]&.first
          time_table_id ||= begin
                              tt = referential.time_tables.build comment: comment
                              save_model tt, resource: resource
                              time_tables_by_service_id[calendar_date.service_id] = [tt.id]
                              tt.id
                            end
          worker.add position: positions[time_table_id], date: Date.parse(calendar_date.date), in_out: calendar_date.exception_type == "1", time_table_id: time_table_id
          positions[time_table_id] += 1
        end
      end
    end
  end

  def find_stop_parent_or_create_message(stop_area_name, parent_station, resource)
    parent = stop_areas.find_by(registration_number: parent_station)
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

  def parse_color(value)
    /\A[\dA-F]{6}\Z/.match(value.upcase).try(:string)
  end

  class InvalidTripTimesError < StandardError; end
  class InvalidTripSingleStopTime < StandardError; end
  class InvalidStopAreaError < StandardError; end
  class InvalidTimeError < StandardError
    attr_reader :time

    def initialize(time)
      super()

      @time = time
    end
  end

  def shape_referential
    workgroup.shape_referential
  end

  def shape_provider
    workbench.default_shape_provider
  end

  def fare_provider
    workbench.default_fare_provider
  end

  def stop_area_provider
    workbench.default_stop_area_provider
  end

  delegate :stop_areas, to: :stop_area_provider
  delegate :connection_links, to: :stop_area_provider

  def index
    @index ||= Index.new
  end

  class Index 
    def initialize
      @fare_ids ||= {}
    end

    def register_fare_id(fare_product, fare_id)
      @fare_ids[fare_product.id] = fare_id
    end

    def fare_product_ids
      @fare_ids.keys
    end
  end

  def import_shapes
    resource = create_resource(:shapes)
    resource.rows_count = source.shapes.count
    resource.save!

    Shapes.new(WithResource.new(self, resource)).import!

    resource.update_status_from_messages
  end

  class Shapes

    def initialize(import)
      @import = import
    end

    attr_reader :import
    delegate :source, :shape_provider, :code_space, :create_message, to: :import

    def import!
      source.shapes.each_slice(1000).each do |gtfs_shapes|
        Shape.transaction do
          gtfs_shapes.each do |gtfs_shape|
            decorator = Decorator.new(gtfs_shape, code_space: code_space)

            unless decorator.valid?
              decorator.errors.each { |error| create_message error }
              next
            end

            shape = collection.by_code(code_space, decorator.code_value).first_or_initialize
            shape.attributes = decorator.shape_attributes
            shape.save!
          end
        end
      end
    end

    def collection
      shape_provider.shapes
    end

    class Decorator < SimpleDelegator
      mattr_accessor :maximum_point_count, default: 10_000
      mattr_reader :factory, default: RGeo::Geos.factory(srid: 4326)

      def initialize(shape, code_space: nil)
        super shape

        @code_space = code_space
      end

      attr_accessor :code_space

      def code_value
        id
      end

      def code
        Code.new(code_space: code_space, value: code_value) if code_space
      end

      def errors
        @errors ||= []
      end

      def valid?
        errors.clear

        if points.count > maximum_point_count
          errors << {
            criticity: :error,
            message_key: :unreasonable_shape,
            message_attributes: { shape_id: id }
          }
        end

        errors.empty?
      end

      def rgeos_points
        points.map do |point|
          factory.point point.longitude, point.latitude
        end
      end

      def rgeos_geometry
        factory.line_string rgeos_points
      end

      def shape_attributes
        {
          geometry: rgeos_geometry,
          codes: [ code ]
        }
      end
    end

  end

  def import_fare_products
    resource = create_resource(:fare_attributes)
    resource.rows_count = source.fare_attributes.count
    resource.save!

    FareProducts.new(self).import!

    resource.update_status_from_messages
  end

  class FareProducts
    def initialize(import)
      @import = import
    end

    attr_reader :import

    delegate :code_space, :companies, :source, :fare_provider, :index, :default_company, to: :import

    def import!
      source.fare_attributes.each do |fare_atribute|
        decorator = Decorator.new(fare_atribute, code_space: code_space, company_scope: companies,
                                                 default_company: default_company, fare_provider: fare_provider)

        product = decorator.build_or_update
        unless product.save
          Rails.logger.warn "Can't save Fare Product #{product.inspect}"
          next
        end

        index.register_fare_id product, decorator.code_value
      end
    end

    class Decorator < SimpleDelegator
      def initialize(fare_attribute, code_space: nil, company_scope: nil, default_company: nil, fare_provider: nil)
        super fare_attribute

        @code_space = code_space
        @company_scope = company_scope
        @fare_provider = fare_provider
        @default_company = default_company
      end

      attr_accessor :code_space, :company_scope, :fare_provider, :default_company

      def build_or_update
        return unless fare_provider

        fare_provider.fare_products.first_or_initialize_by_code(code_space, code_value).tap do |product|
          product.attributes = attributes
        end
      end

      def code_value
        fare_id
      end

      def name
        fare_id
      end

      def price_cents
        (price.to_f * 100).round
      end

      def company
        if agency_id.blank?
          default_company
        else
          company_scope&.find_by(registration_number: agency_id)
        end
      end

      def attributes
        # Managed: fare_id, price, agency_id
        # Ignored: currency_type, payment_method, transfers, transfer_duration

        {
          name: name,
          price_cents: price_cents,
          company: company
        }
      end
    end
  end

  def import_fare_validities
    resource = create_resource(:fare_rules)
    resource.rows_count = source.fare_rules.count
    resource.save!

    FareValidities.new(self).import!

    resource.update_status_from_messages
  end

  class FareValidities
    def initialize(import)
      @import = import
    end

    attr_reader :import

    delegate :code_space, :lines, :source, :fare_provider, :index, to: :import

    def import!
      source.fare_rules.each do |fare_rule|
        decorator = Decorator.new(fare_rule, code_space: code_space, fare_provider: fare_provider, line_scope: lines)

        validity = decorator.build_or_update
        unless validity.save
          Rails.logger.warn "Can't save Fare Validity #{validity.inspect}"
          next
        end

        fare_validity_ids << validity.id
      end

      clean_fare_validities
    end

    def fare_validity_ids
      @fare_validity_ids ||= []
    end

    def clean_fare_validities
      imported_products = fare_provider.fare_products.where(id: index.fare_product_ids)
      not_imported_fare_validities = fare_provider.fare_validities.where.not(id: fare_validity_ids)

      not_imported_fare_validities.by_products(imported_products).destroy_all
    end

    class Decorator < SimpleDelegator
      def initialize(fare_rule, code_space: nil, line_scope: nil, fare_provider: nil)
        super fare_rule

        @code_space = code_space
        @line_scope = line_scope
        @fare_provider = fare_provider
      end

      attr_accessor :code_space, :line_scope, :fare_provider

      delegate :fare_validities, :fare_products, :fare_zones, to: :fare_provider, allow_nil: true

      def build_or_update
        return unless fare_validities

        fare_validities.first_or_initialize_by_code(code_space, code_value).tap do |validity|
          validity.attributes = attributes
        end
      end

      def code_value
        # GTFS Fare Rules have no id
        # The primary key is defined as "*" ...

        "#{fare_id}-#{route_id}-#{origin_id}-#{destination_id}-#{contains_id}"
      end

      def attributes
        {
          name: name,
          products: [product],
          expression: expression
        }
      end

      def name
        NameBuilder.new(self).name
      end

      # Create a Validity name like "C2 - Zones A > D - Zone B"
      class NameBuilder
        def initialize(decorator)
          @decorator = decorator
        end

        attr_accessor :decorator

        delegate :line, :origin_zone, :destination_zone, :contains_zone, to: :decorator

        def name
          [
            line_name,
            zone_to_zone_name,
            zone_name
          ].compact.join(' - ')
        end

        def line_name
          line&.name
        end

        def zone_to_zone_name
          return unless origin_zone || destination_zone

          parts = ['Zones', origin_zone&.name, '>', destination_zone&.name]
          parts.compact.join(' ')
        end

        def zone_name
          "Zone #{contains_zone&.name}" if contains_zone
        end
      end

      def product
        return unless fare_products && fare_id.present?

        fare_products.by_code(code_space, fare_id).first
      end

      def line
        line_scope.find_by(registration_number: route_id) if line_scope && route_id.present?
      end

      def find_or_create_zone(zone_id)
        return unless fare_zones && zone_id.present?

        fare_zones.first_or_create_by_code(code_space, zone_id) do |zone|
          zone.name = zone_id
        end
      end

      def origin_zone
        find_or_create_zone(origin_id)
      end

      def destination_zone
        find_or_create_zone(destination_id)
      end

      def contains_zone
        find_or_create_zone(contains_id)
      end

      def line_expression
        Fare::Validity::Expression::Line.new(line: line) if line
      end

      def zone_to_zone_expression
        return unless origin_zone || destination_zone

        Fare::Validity::Expression::ZoneToZone.new(from: origin_zone, to: destination_zone)
      end

      def zone_expression
        Fare::Validity::Expression::Zone.new(zone: contains_zone) if contains_zone
      end

      def expressions
        @expressions ||= [line_expression, zone_to_zone_expression, zone_expression].compact
      end

      def expression
        if expressions.many?
          Fare::Validity::Expression::Composite.new(expressions: expressions)
        else
          expressions.first
        end
      end
    end
  end

  def import_services
    resource = create_resource(:services)
    # TODO: any performance impact ?
    resource.rows_count = source.services.count
    resource.save!

    Services.new(WithResource.new(self, resource)).import!

    resource.update_status_from_messages
  end

  class Services
    def initialize(import)
      @import = import
    end

    attr_reader :import

    delegate :source, :time_tables_by_service_id, to: :import

    def import!
      # Retrieve both calendar and associated calendar_dates into a single GTFS::Service model
      source.services.each do |service|
        decorator = Decorator.new(service)

        # unless decorator.valid?
        #   # Error ?
        #   next
        # end

        time_table = decorator.time_table

        # TODO: use inserter
        next unless time_table.save

        # TODO: replace by an index
        time_tables_by_service_id[decorator.service_id] = [time_table.id]
      end
    end

    class Decorator < SimpleDelegator
      # Returns a Timetable::DaysOfWeek according to GTFS Service monday?/.../sunday?
      def days_of_week
        Timetable::DaysOfWeek.new.tap do |days_of_week|
          %i[monday tuesday wednesday thursday friday saturday sunday].each do |day|
            days_of_week.enable day if send "#{day}?"
          end
        end
      end

      # Returns a Period according to GTFS Service date_range
      def period
        Period.for_range date_range
      end

      def included_dates
        calendar_dates.select(&:included?).map(&:ruby_date).compact
      end

      def excluded_dates
        calendar_dates.select(&:excluded?).map(&:ruby_date).compact
      end

      def memory_timetable
        @memory_timetable ||= Timetable.new(
          period: Timetable::Period.from(period, days_of_week),
          included_dates: included_dates,
          excluded_dates: excluded_dates
        ).normalize!
      end

      def name
        service_id
      end

      delegate :empty?, to: :memory_timetable

      def time_table
        @time_table ||= Chouette::TimeTable.new(comment: name).apply(memory_timetable)
      end
    end
  end
end
