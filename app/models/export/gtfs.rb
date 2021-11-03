class Export::Gtfs < Export::Base
  include LocalExportSupport

  option :period, default_value: 'all_periods', enumerize: %w[all_periods only_next_days]
  option :duration
  option :exported_lines, default_value: 'all_line_ids', enumerize: %w[line_ids company_ids line_provider_ids all_line_ids]
  option :line_ids, serialize: :map_ids
  option :company_ids, serialize: :map_ids
  option :line_provider_ids, serialize: :map_ids
  option :prefer_referent_stop_area, required: true, default_value: false, enumerize: [true, false], serialize: ActiveModel::Type::Boolean
  option :ignore_single_stop_station, required: true, default_value: false, enumerize: [true, false], serialize: ActiveModel::Type::Boolean

  DEFAULT_AGENCY_ID = "chouette_default"
  DEFAULT_TIMEZONE = "Etc/UTC"

  @skip_empty_exports = true

  def zip_file_name
    @zip_file_name ||= "chouette-its-#{Time.now.to_i}"
  end

  def generate_export_file
    # FIXME
    tmp_dir = Dir.mktmpdir
    export_to_dir tmp_dir
    File.open File.join(tmp_dir, "#{zip_file_name}.zip")
  end

  attr_reader :target

  def target
    @target ||= GTFS::Target.new(Tempfile.new(["export#{id}",'.zip']))
  end

  def export_to_dir(directory)
    CustomFieldsSupport.within_workgroup(referential.workgroup) do
      operations_count = 7

      # FIXME
      @target = GTFS::Target.new(File.join(directory, "#{zip_file_name}.zip"))

      Companies.new(self).export_part
      notify_progress 1.0/operations_count

      StopAreas.new(self).export_part
      notify_progress 2.0/operations_count

      Lines.new(self).export_part
      notify_progress 3.0/operations_count

      Chouette::Benchmark.measure "transfers" do
        export_transfers_to target
        notify_progress 4.0/operations_count
      end

      Shapes.new(self).export_part
      notify_progress 5.0/operations_count

      # Export Trips
      TimeTables.new(self).export_part
      VehicleJourneys.new(self).export_part
      notify_progress 6.0/operations_count

      # Export stop_times.txt
      filter_non_commercial = referential.stop_areas.non_commercial.exists?
      ignore_time_zone = !export_scope.stop_areas.with_time_zone.exists?

      VehicleJourneyAtStops.new(self, filter_non_commercial: filter_non_commercial, ignore_time_zone: ignore_time_zone).export_part
      notify_progress 7.0/operations_count
    end

    target.close
  end

  # For legacy specs
  def export_lines_to(target)
    @target = target
    Lines.new(self).export_part
  end

  def export_companies_to(target)
    @target = target
    Companies.new(self).export_part
  end

  def exported_stop_areas
    parents = Chouette::StopArea.all_parents(export_scope.stop_areas.where(area_type: 'zdep'), ignore_mono_parent: ignore_single_stop_station)
    Chouette::StopArea.union(export_scope.stop_areas, parents).where(kind: :commercial)
  end

  def export_stop_areas_to(target)
    @target = target
    StopAreas.new(self).export_part
  end

  def export_transfers_to(target)
    stop_ids = exported_stop_areas.select(:id).to_sql
    connections = referential.stop_area_referential.connection_links.where("departure_id IN (#{stop_ids}) AND arrival_id IN (#{stop_ids})")
    transfers = {}
    stops = connections.map do |c|
      # all transfers are both ways
      key = [index.stop_id(c.departure), index.stop_id(c.arrival)].sort
      transfers[key] = c.default_duration
    end.uniq

    transfers.each do |stops, min_transfer_time|
      target.transfers << {
        from_stop_id: stops.first,
        to_stop_id: stops.last,
        type: '2',
        min_transfer_time: min_transfer_time
      }
    end
  end

  def index
    @index ||= Index.new
  end

  def code_spaces
    @code_spaces ||= CodeSpaces.new code_space, scope: export_scope
  end

  # Use dedicated "Resource" Find an unique code for a given Resource
  #
  # @example
  #   code_sapces.shapes.unique_code(shape)
  class CodeSpaces

    # Manage only a single CodeSpace for the moment
    def initialize(code_space, scope: nil)
      @code_space = code_space
      @scope = scope
    end

    attr_reader :scope

    def create_resource(resource_class)
      Resource.new code_space(resource_class), resource_class, scope: scope
    end

    def vehicle_journeys
      @vehicle_journeys ||= create_resource Chouette::VehicleJourney
    end

    def shapes
      @shapes ||= create_resource Shape
    end

    def code_space(resource_class)
      # Manage only a single CodeSpace for the moment
      @code_space
    end

    class Resource

      def initialize(code_space, resource_class, scope: nil)
        @code_space = code_space
        @resource_class = resource_class
        @scope = scope
      end

      attr_reader :code_space, :resource_class, :scope

      def unique_code(resource)
        candidates = candidate_codes(resource)
        return nil unless candidates.one?

        candidate_value = candidates.first.value
        return nil if duplicated?(candidate_value)

        candidate_value
      end

      def resource_collection
        resource_class.model_name.plural
      end

      def resources
        scope.send resource_collection
      end

      def resource_codes
        codes.where(code_space: code_space, resource: resources)
      end

      def codes
        # FIXME
        resource_class == Chouette::VehicleJourney ?
          scope.referential_codes : scope.codes
      end

      def duplicated_code_values
        @duplicated_code_values ||=
          SortedSet.new(resource_codes.select(:value, :resource_id).group(:value).having("count(resource_id) > 1").pluck(:value))
      end

      def duplicated?(code_value)
        duplicated_code_values.include? code_value
      end

      def candidate_codes(resource)
        resource.codes.select { |code| code.code_space_id == code_space.id }
      end

    end

  end

  class Index

    def initialize
      @stop_ids = {}
      @route_ids = {}
      @agency_ids = {}
      @trip_ids = Hash.new { |h,k| h[k] = [] }
      @service_ids = Hash.new { |h,k| h[k] = [] }
      @vehicle_journey_time_zones = {}
      @trip_index = 0
      @pickup_type = {}
      @shape_ids = {}
    end

    def stop_id(stop_area_id)
      @stop_ids[stop_area_id]
    end

    def has_stop_id?(stop_area)
      @stop_ids.has_key? stop_area.id
    end

    def register_stop_id(stop_area, stop_id)
      @stop_ids[stop_area.id] = stop_id
    end

    def route_id(line_id)
      @route_ids[line_id]
    end

    def register_route_id(line, route_id)
      @route_ids[line.id] = route_id
    end

    def agency_id(company_id)
      @agency_ids[company_id]
    end

    def register_agency_id(company, agency_id)
      @agency_ids[company.id] = agency_id
    end

    def register_service_ids(time_table, service_ids)
      @service_ids[time_table.id] = service_ids
    end

    def service_ids(time_table_id)
      @service_ids[time_table_id]
    end

    def trip_index
      @trip_index
    end

    def increment_trip_index
      @trip_index += 1
    end

    def register_trip_id(vehicle_journey, trip_id)
      @trip_ids[vehicle_journey.id] << trip_id
    end

    def trip_ids(vehicle_journey_id)
      @trip_ids[vehicle_journey_id]
    end

    def register_pickup_type(vehicle_journey, flexible_service)
      @pickup_type[vehicle_journey.id] = flexible_service
    end

    def pickup_type(vehicle_journey_id)
      @pickup_type[vehicle_journey_id]
    end

    def vehicle_journey_time_zone(vehicle_journey_id)
      @vehicle_journey_time_zones[vehicle_journey_id]
    end

    def register_vehicle_journey_time_zone(vehicle_journey_id, time_zone)
      @vehicle_journey_time_zones[vehicle_journey_id] = time_zone
    end

    def register_shape_id(shape, shape_id)
      @shape_ids[shape.id] = shape_id
    end

    def shape_id(shape_id)
      @shape_ids[shape_id]
    end

  end

  class Part

    attr_reader :export
    def initialize(export, options = {})
      @export = export
      options.each { |k,v| send "#{k}=", v }
    end

    delegate :target, :index, :export_scope, :messages, :date_range, :code_spaces, :public_code_space, :prefer_referent_stop_area, :referential, to: :export

    def part_name
      @part_name ||= self.class.name.demodulize.underscore
    end

    def export_part
      Chouette::Benchmark.measure part_name do
        export!
      end
    end

    # CHOUETTE-960
    def duplicated_registration_numbers
      @duplicated_registration_numbers ||=
        SortedSet.new(referential.send(part_name)
          .select(:registration_number, :id)
          .group(:registration_number)
          .having("count(?) > 1", ActiveRecord::Base.connection.quote_column_name("#{part_name}.id"))
          .where(id: export_scope.send(part_name))
          .pluck(:registration_number))
    end

  end

  class StopAreas < Part

    delegate :exported_stop_areas, to: :export

    def export!
      exported_stop_areas.includes(:referent, :parent, :codes).order("parent_id NULLS first").each_instance do |stop_area|
        decorated_stop_area = handle_referent(stop_area)
        next if index.has_stop_id? decorated_stop_area

        target.stops << decorated_stop_area.stop_attributes
        index.register_stop_id decorated_stop_area, decorated_stop_area.stop_id
      end
    end

    def handle_referent stop_area
      return Decorator.new(stop_area, index, public_code_space, duplicated_registration_numbers) unless prefer_referent_stop_area && stop_area.referent

      decorated_referent = Decorator.new(stop_area.referent, index, public_code_space, duplicated_registration_numbers)
      index.register_stop_id(stop_area, decorated_referent.stop_id)
      return decorated_referent
    end

    class Decorator < SimpleDelegator

      # index is optional to make tests easier
      def initialize(stop_area, index = nil, public_code_space = "", duplicated_registration_numbers = [])
        super stop_area
        @index = index
        @public_code_space = public_code_space
        @duplicated_registration_numbers = duplicated_registration_numbers
      end

      attr_reader :index, :public_code_space, :duplicated_registration_numbers

      def stop_id
        if registration_number.present? &&
           duplicated_registration_numbers.exclude?(registration_number)
          registration_number
        else
          objectid
        end
      end

      def parent_station
        return unless parent_id

        parent_stop_id = index&.stop_id(parent_id)
        Rails.logger.warn "Can't find parent stop_id in index for StopArea #{stop_id}" unless parent_stop_id
        parent_stop_id
      end

      def gtfs_platform_code
        public_code.presence
      end

      def stop_attributes
        {
          id: stop_id,
          code: codes.find_by(code_space: public_code_space)&.value,
          name: name,
          location_type: area_type == 'zdep' ? 0 : 1,
          parent_station: parent_station,
          lat: latitude,
          lon: longitude,
          desc: comment,
          url: url,
          timezone: (time_zone unless parent),
          #code: TO DO
          wheelchair_boarding: mobility_restricted_suitability ? 1 : 0,
          platform_code: gtfs_platform_code
        }
      end

    end

  end


  class Companies < Part

    delegate :companies, :vehicle_journeys, to: :export_scope

    def company_ids
      ids = Set.new
      # OPTIMIZEME pluck is great bu can consume a lot of memory for very large Vehicle Journey collection
      vehicle_journeys.left_joins(route: { line: :company }).
        pluck("vehicle_journeys.id", "vehicle_journeys.company_id", "companies.id", "companies.time_zone").
        each do |vehicle_journey_id, vehicle_journeys_company_id, line_company_id, company_time_zone|

        company_id = vehicle_journeys_company_id.presence || line_company_id.presence || DEFAULT_AGENCY_ID
        ids << company_id

        index.register_vehicle_journey_time_zone vehicle_journey_id, company_time_zone if company_time_zone
      end
      ids
    end

    def create_message(decorated_company)
      if decorated_company.time_zone.blank?
        messages.create({
          criticity: :info,
          message_key: :no_timezone,
          message_attributes: {
            company_name: decorated_company.name
          }
        })
      end
    end

    def export!
      Chouette::Company.where(id: company_ids-[DEFAULT_AGENCY_ID]).order('name').find_each do |company|
        decorated_company = Decorator.new(company, duplicated_registration_numbers)

        create_message decorated_company
        target.agencies << decorated_company.agency_attributes

        index.register_agency_id(decorated_company, decorated_company.agency_id)
      end

      if company_ids.include? DEFAULT_AGENCY_ID
        target.agencies << {
          id: DEFAULT_AGENCY_ID,
          name: "Default Agency",
          timezone: DEFAULT_TIMEZONE,
        }
      end
    end

    class Decorator < SimpleDelegator

      # index is optional to make tests easier
      def initialize(company, duplicated_registration_numbers = [])
        super company
        @duplicated_registration_numbers = duplicated_registration_numbers
      end

      attr_reader :index, :duplicated_registration_numbers

      def agency_id
        @agency_id ||= registration_number && duplicated_registration_numbers.exclude?(registration_number) ? registration_number : objectid
      end

      def timezone
        time_zone.presence || DEFAULT_TIMEZONE
      end

      def agency_attributes
        {
          id: agency_id,
          name: name,
          url: default_contact_url,
          timezone: timezone,
          phone: default_contact_phone,
          email: default_contact_email,
          lang: default_language
          #fare_url: TO DO
        }
      end
    end

  end

  class Lines < Part

    delegate :lines, to: :export_scope

    def create_messages(decorated_line)
      if decorated_line.default_agency?
        messages.create({
          criticity: :info,
          message_key: :no_company,
          message_attributes: {
            line_name: decorated_line.name
          }
        })
      end
    end

    def export!
      lines.find_each do |line|
        decorated_line = Decorator.new(line, index, duplicated_registration_numbers)

        create_messages decorated_line
        target.routes << decorated_line.route_attributes

        index.register_route_id line, decorated_line.route_id
      end
    end

    class Decorator < SimpleDelegator

      # index is optional to make tests easier
      def initialize(line, index = nil, duplicated_registration_numbers = [])
        super line
        @index = index
        @duplicated_registration_numbers = duplicated_registration_numbers
      end

      attr_reader :index, :duplicated_registration_numbers

      def route_id
        if registration_number.present? &&
           duplicated_registration_numbers.exclude?(registration_number)
          registration_number
        else
          objectid
        end
      end

      def route_long_name
        value = (published_name.presence || name)
        value unless value == route_short_name
      end

      def route_short_name
        number
      end

      def self.route_types
        @route_types ||= {
          tram: 0,
          metro: 1,
          rail: 2,
          bus: 3,
          water: 4,
          telecabin: 6,
          funicular: 7,
          coach: 200,
          air: 1100,
          taxi: 1500,
          hireCar: 1506
        }.with_indifferent_access
      end

      def route_type
        unless flexible_service
          self.class.route_types[transport_mode]
        else
          715
        end
      end

      def default_agency?
        route_agency_id == DEFAULT_AGENCY_ID
      end

      def route_agency_id
        index&.agency_id(company_id) || DEFAULT_AGENCY_ID
      end

      def route_attributes
        {
          id: route_id,
          agency_id: route_agency_id,
          long_name: route_long_name,
          short_name: route_short_name,
          type: route_type,
          desc: comment,
          url: url,
          color: color,
          text_color: text_color
        }
      end

    end

  end

  class TimeTables < Part

    delegate :time_tables, to: :export_scope

    def export!
      time_tables.includes(:periods, :dates).find_each do |time_table|
        decorated_time_table = TimeTableDecorator.new(time_table, date_range)

        decorated_time_table.calendars.each { |c| target.calendars << c }
        decorated_time_table.calendar_dates.each { |cd| target.calendar_dates << cd }

        index.register_service_ids time_table, decorated_time_table.service_ids
      end
    end

    class TimeTableDecorator < SimpleDelegator
      # index is optional to make tests easier
      def initialize(time_table, export_date_range = nil)
        super time_table
        @export_date_range = export_date_range
      end

      def service_ids
        @service_ids ||= Set.new
      end

      def periods
        @periods ||= if @export_date_range.nil?
          super
        else
            super.select { |p| p.range & @export_date_range }
        end
      end

      def dates
        @dates ||= if @export_date_range.nil?
          super
        else
          super.select {|d| (d.in_out && @export_date_range.cover?(d.date)) || (!d.in_out && periods.select{|p| p.range.cover? d.date}.any?)}
        end
      end

      def decorated_periods
        @decorated_periods ||= periods.map do |period|
          PeriodDecorator.new(period)
        end
      end

      def calendars
        decorated_periods.map do |decorated_period|
          with_service_id decorated_period.calendar_attributes,
                          period_service_id(decorated_period)
        end
      end

      def calendar_dates
        dates.map do |date|
          with_service_id DateDecorator.new(date).calendar_date_attributes,
                          date_service_id(date)
        end
      end

      def with_service_id(attributes, service_id)
        service_ids << service_id
        attributes.merge service_id: service_id
      end

      def first_period?(period)
        period == decorated_periods.first
      end

      def default_service_id
        objectid
      end

      def period_service_id(decorated_period)
        if first_period? decorated_period
          default_service_id
        else
          decorated_period.calendar_service_id
        end
      end

      def associated_period(date)
        decorated_periods.find do |decorated_period|
          decorated_period.include?(date)
        end
      end

      def date_service_id(date)
        period = associated_period(date)
        if period
          period_service_id period
        else
          default_service_id
        end
      end
    end

    class PeriodDecorator < SimpleDelegator
      def range
        @range ||= super
      end

      def calendar_service_id
        id
      end

      %w{monday tuesday wednesday thursday friday saturday sunday}.each do |day|
        define_method "calendar_#{day}" do
          time_table.send(day) ? 1 : 0
        end
      end

      def calendar_start_date
        period_start.strftime('%Y%m%d')
      end

      def calendar_end_date
        period_end.strftime('%Y%m%d')
      end

      def calendar_attributes
        {
          start_date: calendar_start_date,
          end_date: calendar_end_date,
          monday: calendar_monday,
          tuesday: calendar_tuesday,
          wednesday: calendar_wednesday,
          thursday: calendar_thursday,
          friday: calendar_friday,
          saturday: calendar_saturday,
          sunday: calendar_sunday
        }
      end

      def include?(date)
        range.include?(date.date)
      end
    end

    class DateDecorator < SimpleDelegator
      def calendar_date_date
        date.strftime('%Y%m%d')
      end

      def calendar_date_exception_type
        in_out ? 1 : 2
      end

      def calendar_date_attributes
        {
          date: calendar_date_date,
          exception_type: calendar_date_exception_type
        }
      end
    end
  end

  # For legacy specs
  def export_vehicle_journeys_to(target)
    @target = target
    TimeTables.new(self).export!
    VehicleJourneys.new(self).export!
  end

  class VehicleJourneys < Part

    delegate :vehicle_journeys, to: :export_scope

    def export!
      vehicle_journeys.includes(:time_tables, :journey_pattern, :codes, route: :line).find_each do |vehicle_journey|
        decorated_vehicle_journey = Decorator.new(vehicle_journey, index: index, code_provider: code_spaces.vehicle_journeys)

        decorated_vehicle_journey.service_ids.each do |service_id|
          trip_attributes = decorated_vehicle_journey.trip_attributes(service_id)

          target.trips << trip_attributes
          index.register_trip_id vehicle_journey, trip_attributes[:id]

          flexible_service = vehicle_journey.flexible_service || vehicle_journey.line.flexible_service || false
          index.register_pickup_type vehicle_journey, flexible_service
        end
      end
    end

    class Decorator < SimpleDelegator

      # index is optional to make tests easier
      def initialize(vehicle_journey, index: nil, code_provider: nil)
        super vehicle_journey
        @index = index
        @code_provider = code_provider
      end

      attr_reader :index
      attr_accessor :code_provider

      def route_id
        index.route_id(route.line_id) if route
      end

      def trip_id(suffix = nil)
        if single_service_id?
          base_trip_id
        else
          "#{base_trip_id}-#{suffix}"
        end
      end

      def base_trip_id
        gtfs_code || objectid
      end

      def gtfs_code
        code_provider.unique_code(self) if code_provider
      end

      def service_ids
        return [] unless index

        @service_ids ||= time_table_ids.each_with_object(Set.new) do |time_table_id, all|
          all.merge index.service_ids(time_table_id)
        end
      end

      def single_service_id?
        @single_service_id ||= service_ids.one?
      end

      def direction_id
        if route && route.wayback.present?
          route.wayback == 'outbound' ? 0 : 1
        end
      end

      def gtfs_shape_id
        index.shape_id(journey_pattern&.shape_id)
      end

      def trip_attributes(service_id)
        {
          route_id: route_id,
          service_id:  service_id,
          id: trip_id(service_id),
          short_name: published_journey_name,
          direction_id: direction_id,
          shape_id: gtfs_shape_id
          #headsign: TO DO
          #block_id: TO DO
          #wheelchair_accessible: TO DO
          #bikes_allowed: TO DO
        }
      end
    end
  end

  # For legacy specs
  def export_vehicle_journey_at_stops_to(target)
    @target = target
    VehicleJourneyAtStops.new(self).export!
  end

  class VehicleJourneyAtStops < Part

    delegate :prefer_referent_stop_area, to: :export
    attr_writer :filter_non_commercial, :ignore_time_zone

    def filter_non_commercial?
      # false ||= true -> true :-/
      @filter_non_commercial = true if @filter_non_commercial.nil?

      @filter_non_commercial
    end

    def ignore_time_zone?
      @ignore_time_zone
    end

    def vehicle_journey_at_stops
      @vehicle_journey_at_stops ||=
        begin
          base_scope = export_scope.vehicle_journey_at_stops

          if filter_non_commercial?
            Rails.logger.warn "Export GTFS #{export.id} uses non optimized non_commercial filter"
            if prefer_referent_stop_area
              base_scope = base_scope.left_joins(stop_point: {stop_area: :referent})
              base_scope = base_scope.where.not("stop_areas.kind" => "non_commercial").where("referents_public_stop_areas.kind != 'non_commercial' OR referents_public_stop_areas.kind is NULL")
            else
              base_scope = base_scope.joins(stop_point: :stop_area).where("stop_areas.kind" => "commercial")
            end
          end

          base_scope
        end
    end

    def export!
      attributes = [
        :departure_time,
        :arrival_time,
        :departure_day_offset,
        :arrival_day_offset,
        :vehicle_journey_id,
        "vehicle_journey_at_stops.stop_area_id as stop_area_id",
        "stop_points.stop_area_id as parent_stop_area_id",
        "stop_points.position",
        "stop_points.for_boarding as for_boarding",
        "stop_points.for_alighting as for_alighting"
      ]
      vehicle_journey_at_stops.joins(:stop_point).select(*attributes).each_row do |vjas_raw_hash|
        decorated_vehicle_journey_at_stop = Decorator.new(vjas_raw_hash, index: index, ignore_time_zone: ignore_time_zone?)
        # Duplicate the stop time for each exported trip
        index.trip_ids(vjas_raw_hash["vehicle_journey_id"].to_i).each do |trip_id|
          route_attributes = decorated_vehicle_journey_at_stop.stop_time_attributes
          route_attributes.merge!(trip_id: trip_id)
          target.stop_times << route_attributes
        end
      end
    end

    class Decorator

      # index is optional to make tests easier
      def initialize(vjas_raw_hash, index: nil, ignore_time_zone: false)
        @attributes = vjas_raw_hash
        @index = index
        @ignore_time_zone = ignore_time_zone
      end

      %w{
        vehicle_journey_id departure_time departure_day_offset arrival_time arrival_day_offset position for_boarding for_alighting
      }.each do |attribute|
        define_method(attribute) do
          @attributes[attribute]
        end
      end

      attr_reader :index

      def ignore_time_zone?
        @ignore_time_zone
      end

      def time_zone
        index&.vehicle_journey_time_zone(vehicle_journey_id) unless ignore_time_zone?
      end

      def departure_time_of_day
        @departure_time_of_day ||= TimeOfDay.parse(departure_time, day_offset: departure_day_offset) if departure_time
      end

      def departure_local_time_of_day
       @departure_local_time_of_day ||= departure_time_of_day&.with_zone(time_zone)
      end

      def arrival_time_of_day
        @arrival_time_of_day ||= TimeOfDay.parse(arrival_time, day_offset: arrival_day_offset) if arrival_time
      end

      def arrival_local_time_of_day
        @arrival_local_time_of_day ||= arrival_time_of_day&.with_zone(time_zone)
      end

      def stop_time_departure_time
        GTFS::Time.create(departure_local_time_of_day).to_s if departure_local_time_of_day
      end

      def stop_time_arrival_time
        GTFS::Time.create(arrival_local_time_of_day).to_s if arrival_local_time_of_day
      end

      def stop_area_id
        @attributes["stop_area_id"] || @attributes["parent_stop_area_id"]
      end

      def stop_time_stop_id
        index&.stop_id(stop_area_id)
      end

      def drop_off_type
        return 1 if for_alighting == 'forbidden'
      end

      def pickup_type
        return 1 if for_boarding == 'forbidden'
        index&.pickup_type(vehicle_journey_id) ? 2 : 0
      end

      def stop_time_attributes
        { departure_time: stop_time_departure_time,
          arrival_time: stop_time_arrival_time,
          stop_id: stop_time_stop_id,
          stop_sequence: position,
          pickup_type: pickup_type,
          drop_off_type: drop_off_type
        }
      end

    end

  end

  class Shapes < Part

    delegate :shapes, to: :export_scope

    def export!
      shapes.find_each do |shape|
        decorated_shape = Decorator.new(shape, code_provider: code_spaces.shapes)
        target.shapes << decorated_shape.gtfs_shape

        index.register_shape_id shape, decorated_shape.gtfs_id
      end
    end

    class Decorator < SimpleDelegator

      def initialize(shape, code_provider: nil)
        super shape
        @code_provider = code_provider
      end

      attr_reader :code_provider

      def gtfs_id
        gtfs_code || uuid
      end

      def gtfs_code
        code_provider.unique_code(self) if code_provider
      end

      def gtfs_shape_points
        geometry.points.map do |point|
          GTFS::ShapePoint.new(latitude: point.y,longitude: point.x)
        end
      end

      def gtfs_shape
        GTFS::Shape.new(id: gtfs_id).tap do |shape|
          gtfs_shape_points.each { |point| shape.points << point }
        end
      end

    end

  end
end
