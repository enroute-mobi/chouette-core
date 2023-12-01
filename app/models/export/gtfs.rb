# frozen_string_literal: true

class Export::Gtfs < Export::Base
  include LocalExportSupport

  option :period, default_value: 'all_periods', enumerize: %w[all_periods only_next_days]
  option :duration
  option :exported_lines, default_value: 'all_line_ids', enumerize: %w[line_ids company_ids line_provider_ids all_line_ids]
  option :line_ids, serialize: :map_ids
  option :company_ids, serialize: :map_ids
  option :line_provider_ids, serialize: :map_ids
  option :prefer_referent_stop_area, required: true, default_value: false, enumerize: [true, false], serialize: ActiveModel::Type::Boolean
  option :prefer_referent_line, required: true, default_value: false, enumerize: [true, false], serialize: ActiveModel::Type::Boolean
  option :ignore_single_stop_station, required: true, default_value: false, enumerize: [true, false], serialize: ActiveModel::Type::Boolean
  option :prefer_referent_company, required: true, default_value: false, enumerize: [true, false], serialize: ActiveModel::Type::Boolean
  option :ignore_parent_stop_places, required: true, default_value: false, enumerize: [true, false], serialize: ActiveModel::Type::Boolean


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
    operations_count = 8

    # FIXME
    @target = GTFS::Target.new(File.join(directory, "#{zip_file_name}.zip"))

    Companies.new(self).export_part

    StopAreas.new(self).export_part

    Lines.new(self).export_part

    Chouette::Benchmark.measure "transfers" do
      export_transfers_to target
    end

    Shapes.new(self).export_part

    # Export Trips
    TimeTables.new(self).export_part
    VehicleJourneys.new(self).export_part

    # Export stop_times.txt
    JourneyPatternDistances.new(self).export_part
    filter_non_commercial = referential.stop_areas.non_commercial.exists?
    ignore_time_zone = !export_scope.stop_areas.with_time_zone.exists?

    VehicleJourneyAtStops.new(self, filter_non_commercial: filter_non_commercial, ignore_time_zone: ignore_time_zone).export_part

    VehicleJourneyCompany.new(self).export_part

    FeedInfo.new(self).export_part

    FareProducts.new(self).export_part
    FareValidities.new(self).export_part

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

  alias ignore_parent_stop_places? ignore_parent_stop_places

  def exported_stop_areas
    unless ignore_parent_stop_places?
      parents = Chouette::StopArea.all_parents(export_scope.stop_areas.where(area_type: 'zdep'), ignore_mono_parent: ignore_single_stop_station)
      Chouette::StopArea.union(export_scope.stop_areas, parents).where(kind: :commercial)
    else
      export_scope.stop_areas
    end
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

  # Regroups a Service identifier (service_id) and its validity period
  class Service
    def initialize(id, validity_period: nil)
      @id = id
      @validity_period = validity_period
    end

    attr_accessor :id, :validity_period

    def ==(other)
      id == other&.id
    end

    def extend_validity_period(period_or_date)
      period = Period.for(period_or_date)
      self.validity_period = validity_period&.extend(period) || period
    end
  end
  class Index

    def initialize
      @stop_ids = {}
      @route_ids = {}
      @agency_ids = {}
      @trip_ids = Hash.new { |h,k| h[k] = [] }
      @services = Hash.new { |h,k| h[k] = [] }
      @vehicle_journey_time_zones = {}
      @trip_index = 0
      @pickup_type = {}
      @shape_ids = {}
      @journey_pattern_distances = {}
      @line_referents = {}
    end

    attr_reader :default_company

    def register_journey_pattern_distance(journey_pattern_id, stop_point_id, value)
      @journey_pattern_distances[[journey_pattern_id, stop_point_id]] = value
    end

    def journey_pattern_distance(journey_pattern_id, stop_point_id)
      return unless journey_pattern_id && stop_point_id

      @journey_pattern_distances[[journey_pattern_id, stop_point_id]]
    end

    def default_company=(value)
      @default_company ||= value
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

    def register_services(time_table, services)
      @services[time_table.id] = services
    end

    def services(time_table_id)
      @services[time_table_id]
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

    delegate :target, :index, :export_scope, :messages, :date_range, :code_spaces, :public_code_space, :code_space,
             :prefer_referent_stop_area, :prefer_referent_company, :prefer_referent_line, :referential, to: :export

    def part_name
      @part_name ||= self.class.name.demodulize.underscore
    end

    def export_part
      Chouette::Benchmark.measure part_name do
        export!
      end
    end

    def exported_models
      send(part_name)
    end

    def duplicated_registration_numbers
      @duplicated_registration_numbers ||=
        begin
          # With complexe scopes, group by is applying on joins result where several lines, vehicle journeys
          # are present, giving false duplicated registration numbers
          #
          # The subquery allows to retrieve only distinct id and registration_number.
          query = <<~SQL
            select registration_number
            from (#{exported_models.select(:id, :registration_number).distinct.to_sql}) as id_and_registration_number
            group by registration_number having count(id) > 1;
          SQL

          SortedSet.new(ActiveRecord::Base.connection.select_values(query))
        end
    end
  end

  class StopAreas < Part

    def stop_areas
      export.exported_stop_areas
    end

    def export!
      stop_areas.includes(:referent, :parent, :codes, fare_zones: :codes).order("parent_id NULLS first").each_instance do |stop_area|
        decorated_stop_area = handle_referent(stop_area)
        next if index.has_stop_id? decorated_stop_area

        target.stops << decorated_stop_area.stop_attributes
        index.register_stop_id decorated_stop_area, decorated_stop_area.stop_id
      end
    end

    def handle_referent stop_area
      unless prefer_referent_stop_area && stop_area.referent
        return Decorator.new(stop_area, index, public_code_space, duplicated_registration_numbers, code_space)
      end

      decorated_referent = Decorator.new(stop_area.referent, index, public_code_space,
                                         duplicated_registration_numbers, code_space)
      index.register_stop_id(stop_area, decorated_referent.stop_id)
      return decorated_referent
    end

    class Decorator < SimpleDelegator

      # index is optional to make tests easier
      def initialize(stop_area, index = nil, public_code_space = "", duplicated_registration_numbers = [], code_space = nil)
        super stop_area
        @index = index
        @public_code_space = public_code_space
        @duplicated_registration_numbers = duplicated_registration_numbers
        @code_space = code_space
      end

      attr_reader :index, :public_code_space, :duplicated_registration_numbers, :code_space

      def zone_id
        code_value || fare_zone&.uuid
      end

      def code_value
        return unless fare_zone_codes

        fare_zone_codes.find { |code| code.code_space && code.code_space == code_space }&.value
      end

      def fare_zone_codes
        fare_zone&.codes
      end

      def fare_zone
        @fare_zone ||= fare_zones&.first
      end

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

      def gtfs_wheelchair_boarding
        case mobility_impaired_accessibility
        when nil, 'unknown'
          '0'
        when 'yes'
          '1'
        when 'no'
          '2'
        end
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
          wheelchair_boarding: gtfs_wheelchair_boarding,
          platform_code: gtfs_platform_code,
          zone_id: zone_id
        }
      end

    end

  end

  class Companies < Part

    delegate :vehicle_journeys, to: :export_scope

    def vehicle_journey_count_by_company
      @vehicle_journey_count_by_company ||= Hash.new { |h,k| h[k] = 0 }
    end

    def company_ids
      ids = Set.new
      # OPTIMIZEME pluck is great bu can consume a lot of memory for very large Vehicle Journey collection
      vehicle_journeys.left_joins(route: { line: :company }).
        pluck("vehicle_journeys.id", "companies.id", "companies.time_zone").
        each do |vehicle_journey_id, line_company_id, company_time_zone|

        company_id = line_company_id.presence || DEFAULT_AGENCY_ID
        time_zone = company_time_zone

        if prefer_referent_company && (referent = referents[company_id]).present?
          company_id = referent.id
          time_zone = referent.time_zone
        end

        vehicle_journey_count_by_company[company_id] += 1

        ids << company_id
        index.register_vehicle_journey_time_zone vehicle_journey_id, time_zone if time_zone
      end
      ids
    end

    def most_used_company_id
      vehicle_journey_count_by_company.max_by{|k,v| v}&.first
    end

    def default_company
      referential.companies.find_by(id: most_used_company_id)
    end

    def referents
      @referents ||= export_scope.companies.includes(:referent).where.not(referent: nil).map { |company| [ company.id, company.referent ] }.to_h
    end

    def companies
      @companies ||= referential.companies.where(id: company_ids-[DEFAULT_AGENCY_ID])
    end

    def handle_referent(company, duplicated_registration_numbers)
      decorated_company = Decorator.new(company, duplicated_registration_numbers)

      index.register_agency_id(decorated_company, decorated_company.agency_id)

      return decorated_company unless prefer_referent_company

      company.particulars.each do |particular_company|
        index.register_agency_id(particular_company, decorated_company.agency_id)
      end

      decorated_company
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
      companies.includes(:particulars).order("name").find_each do |company|
        decorated_company = handle_referent(company, duplicated_registration_numbers)

        create_message decorated_company
        target.agencies << decorated_company.agency_attributes
      end

      if company_ids.include? DEFAULT_AGENCY_ID
        target.agencies << {
          id: DEFAULT_AGENCY_ID,
          name: "Default Agency",
          timezone: DEFAULT_TIMEZONE,
        }
      end

      index.default_company = default_company
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
          lang: default_language,
          fare_url: fare_url
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
      lines.includes(:referent).find_each do |line|
        exported_line = (prefer_referent_line ? line.referent : line) || line
        decorated_line = Decorator.new(exported_line, index, duplicated_registration_numbers)

        unless line_referent_exported?(exported_line)
          create_messages decorated_line
          target.routes << decorated_line.route_attributes
          register_line_referent(exported_line)
        end
        index.register_route_id line, decorated_line.route_id
      end
    end

    def register_line_referent(exported_line)
      return unless exported_line.referent?

      line_referents[exported_line.id] = true
    end

    def line_referent_exported?(exported_line)
      line_referents[exported_line.id]
    end

    def line_referents
      @line_referents ||= {}
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
          return 103 if transport_mode == 'rail' && transport_submode == 'interregionalRail'
          return 204 if transport_mode == 'coach' && transport_submode == 'regionalCoach'
          return 205 if transport_mode == 'coach' && transport_submode == 'specialCoach'
          return 208 if transport_mode == 'coach' && transport_submode == 'commuterCoach'
          return 713 if transport_mode == 'bus' && transport_submode == 'schoolAndPublicServiceBus'
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
        decorated_time_table = TimeTableDecorator.new(time_table, export_scope.validity_period)

        decorated_time_table.calendars.each { |c| target.calendars << c }
        decorated_time_table.calendar_dates.each { |cd| target.calendar_dates << cd }

        index.register_services time_table, decorated_time_table.services
      end
    end

    class TimeTableDecorator < SimpleDelegator
      # index is optional to make tests easier
      def initialize(time_table, export_date_range = nil)
        super time_table
        @export_date_range = export_date_range

        @services_by_id ||= Hash.new { |h, service_id| h[service_id] = Service.new(service_id) }
      end

      def service(service_id)
        @services_by_id[service_id]
      end

      def services
        @services_by_id.values
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
                          period_service_id(decorated_period),
                          decorated_period.range
        end
      end

      def calendar_dates
        dates.map do |date|
          with_service_id DateDecorator.new(date).calendar_date_attributes,
                          date_service_id(date),
                          date.date
        end
      end

      def with_service_id(attributes, service_id, period_or_date)
        service(service_id).extend_validity_period period_or_date
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

        decorated_vehicle_journey.services.each do |service|
          trip_attributes = decorated_vehicle_journey.trip_attributes(service)

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

      def trip_id(service)
        if service == preferred_service
          base_trip_id
        else
          "#{base_trip_id}-#{service.id}"
        end
      end

      def base_trip_id
        gtfs_code || objectid
      end

      def gtfs_code
        code_provider.unique_code(self) if code_provider
      end

      def services
        return [] unless index

        @services ||= time_table_ids.each_with_object(Set.new) do |time_table_id, all|
          all.merge index.services(time_table_id)
        end
      end

      def preferred_service
        @preferred_service ||= ServiceFinder.new(services).preferred
      end

      def direction_id
        if route && route.wayback.present?
          route.wayback == 'outbound' ? 0 : 1
        end
      end

      def gtfs_shape_id
        index.shape_id(journey_pattern&.shape_id)
      end

      def gtfs_headsign
        journey_pattern&.published_name
      end

      def trip_attributes(service)
        {
          route_id: route_id,
          service_id: service.id,
          id: trip_id(service),
          short_name: published_journey_name,
          direction_id: direction_id,
          shape_id: gtfs_shape_id,
          headsign: gtfs_headsign
          # block_id: TO DO
          # wheelchair_accessible: TO DO
          # bikes_allowed: TO DO
        }
      end
    end

    # Find Preferred Service in a collection
    class ServiceFinder
      def initialize(services)
        @services = services
      end

      def preferred
        single || current || self.next
      end

      def single
        first if one?
      end

      def current
        find { |service| service.validity_period.include?(today) }
      end

      def nexts
        select { |service| service.validity_period.from > today }
      end

      def next
        nexts.min_by { |service| service.validity_period.from }
      end

      attr_reader :services

      delegate :find, :select, :first, :one?, to: :services

      def today
        @today ||= Date.current
      end
    end
  end

  class JourneyPatternDistances  < Part

    def journey_patterns
      export_scope.journey_patterns.includes(:stop_points).where.not(costs: [{}, nil])
    end

    def export!
      journey_patterns.find_each do |journey_pattern|
        journey_pattern.stop_points.find_each do |stop_point|
          index.register_journey_pattern_distance(
            journey_pattern.id,
            stop_point.id,
            journey_pattern.distance_to(stop_point)
          )
        end
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
        'vehicle_journey_at_stops.stop_area_id AS stop_area_id',
        'stop_points.stop_area_id AS parent_stop_area_id',
        'stop_points.position AS position',
        'stop_points.for_boarding AS for_boarding',
        'stop_points.for_alighting AS for_alighting',
        'stop_points.id AS stop_point_id',
        'vehicle_journeys.journey_pattern_id AS journey_pattern_id'
      ]

      vehicle_journey_at_stops.joins(:stop_point, :vehicle_journey).select(*attributes).each_row do |vjas_raw_hash|
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

      %w[
        vehicle_journey_id departure_time departure_day_offset arrival_time arrival_day_offset
        position for_boarding for_alighting journey_pattern_id stop_point_id
      ].each do |attribute|
        define_method(attribute) do
          @attributes[attribute]
        end
      end

      def shape_dist_traveled
        return unless journey_pattern_id && stop_point_id

        journey_pattern_distance = index.journey_pattern_distance(journey_pattern_id, stop_point_id)
        return unless journey_pattern_distance

        journey_pattern_distance.to_f / 1000
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
          drop_off_type: drop_off_type,
          shape_dist_traveled: shape_dist_traveled
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
        distance = 0.0
        last_point = nil

        geometry.points.map do |point|
          point = Geo::Position.from(point)
          distance += point.distance_with(last_point) if last_point
          last_point = point

          GTFS::ShapePoint.new(latitude: point.y, longitude: point.x, dist_traveled: (distance / 1000).round(3))
        end
      end

      def gtfs_shape
        GTFS::Shape.new(id: gtfs_id).tap do |shape|
          gtfs_shape_points.each { |point| shape.points << point }
        end
      end

    end

  end

  class VehicleJourneyCompany < Part
    def export!
      vehicle_journeys.find_each do |vehicle_journey|
        Decorator.new(vehicle_journey, index: index).attributions.each do |attribution|
          target.attributions << attribution
        end
      end
    end

    def vehicle_journeys
      export_scope.vehicle_journeys.joins(route: :line).where.not(company: nil).where("vehicle_journeys.company_id != lines.company_id")
    end

    class Decorator < SimpleDelegator
      attr_reader :index, :vehicle_journey
      def initialize(vehicle_journey, index: nil)
        super vehicle_journey
        @vehicle_journey = vehicle_journey
        @index = index
      end

      def trip_ids
        index ? index.trip_ids(id) : []
      end

      def attributions
        trip_ids.map do |trip_id|
          TripDecorator.new(vehicle_journey, trip_id: trip_id).attribution
        end
      end
    end

    class TripDecorator < SimpleDelegator

      def initialize(vehicle_journey, trip_id: nil)
        super vehicle_journey
        @trip_id = trip_id
      end

      def attribution_attributes
        {
          attribution_id: attribution_id,
          trip_id: trip_id,
          organization_name: organization_name,
          is_operator: is_operator,
        }
      end

      def attribution
        GTFS::Attribution.new attribution_attributes
      end

      def trip_id
        @trip_id || objectid
      end

      def attribution_id
        @attribution_id ||= SecureRandom.uuid
      end

      def organization_name
        company&.name
      end

      def is_operator
        1
      end
    end
  end

  class FeedInfo < Part
    delegate :companies, :validity_period, to: :export_scope

    def export!
      target.feed_infos << Decorator.new(company: company, validity_period: validity_period).feed_info_attributes
    end

    def company
      index.default_company
    end

    class Decorator
      attr_reader :company, :validity_period

      def initialize(company:, validity_period:)
        @company = company
        @validity_period = validity_period
      end

      def feed_info_attributes
        {
          start_date: gtfs_start_date,
          end_date: gtfs_end_date,
          publisher_name: publisher_name,
          publisher_url: publisher_url,
          lang: language
        }
      end

      def start_date
        validity_period&.min
      end

      def gtfs_start_date
        start_date&.strftime('%Y%m%d')
      end

      def end_date
        validity_period&.max
      end

      def gtfs_end_date
        end_date&.strftime('%Y%m%d')
      end

      def publisher_name
        company&.name
      end

      def publisher_url
        company&.default_contact_url
      end

      DEFAULT_LANGUAGE = 'fr'
      def language
        # For the moment, we need to use a default language to avoid
        # invalid feedwhen the user is not aware of this feature
        company&.default_language.presence || DEFAULT_LANGUAGE
      end
    end
  end
  class FareProducts < Part
    delegate :code_space, to: :export
    delegate :fare_products, to: :export_scope

    def export!
      fare_products.find_each do |fare_product|
        decorated_product = Decorator.new(fare_product, index: index, code_space: code_space)
        target.fare_attributes << decorated_product.fare_attribute
      end
    end

    class Decorator < SimpleDelegator
      def initialize(fare_product, index: nil, code_space: nil)
        super fare_product
        @index = index
        @code_space = code_space
      end

      attr_accessor :index, :code_space

      def gtfs_attributes
        {
          fare_id: gtfs_id,
          price: gtfs_price,
          agency_id: gtfs_agency_id,
          # Not managed for the moment
          currency_type: 'EUR',
          payment_method: 1,
          transfers: 0,
          transfer_duration: nil
        }
      end

      def gtfs_id
        gtfs_code || uuid
      end

      def gtfs_price
        price_cents.to_f / 100
      end

      def gtfs_agency_id
        index.agency_id(company.id) if index && company
      end

      def gtfs_code
        codes.where(code_space: code_space).first&.value
        # code_provider.unique_code(self) if code_provider
      end

      def fare_attribute
        GTFS::FareAttribute.new gtfs_attributes
      end
    end
  end

  class FareValidities < Part
    delegate :code_space, to: :export
    delegate :fare_validities, to: :export_scope

    def export!
      fare_validities.includes(:products).find_each do |fare_validity|
        decorated_validity = Decorator.new(fare_validity, index: index, code_space: code_space)

        decorated_validity.fare_rules.each do |fare_rule|
          target.fare_rules << fare_rule
        end
      end
    end

    class Decorator < SimpleDelegator
      def initialize(fare_validity, index: nil, code_space: nil)
        super fare_validity
        @index = index
        @code_space = code_space
      end

      attr_accessor :index, :code_space

      def fare_rules
        products.map do |fare_product|
          GTFS::FareRule.new attributes.merge(fare_id: fare_id(fare_product))
        end
      end

      def fare_id(fare_product)
        fare_product.codes.where(code_space: code_space).first&.value || fare_product.uuid
      end

      def attributes
        {
          route_id: route_id,
          origin_id: origin_id,
          destination_id: destination_id,
          contains_id: contains_id
        }
      end

      def route_id
        index.route_id(line_expression.line_id) if line_expression
      end

      def origin_id
        zone_gtfs_code zone_to_zone_expression&.from
      end

      def destination_id
        zone_gtfs_code zone_to_zone_expression&.to
      end

      def contains_id
        zone_gtfs_code zone_expression&.zone
      end

      def zone_gtfs_code(zone)
        return nil unless zone

        zone.codes.where(code_space: code_space).first&.value || zone.uuid
      end

      def find_expression(klass)
        return expression if expression.is_a?(klass)

        if expression.is_a?(Fare::Validity::Expression::Composite) && expression.logical_link == :and
          return expression.expressions.find { |expression| expression.is_a?(klass) }
        end

        nil
      end

      def line_expression
        @line_expression ||= find_expression Fare::Validity::Expression::Line
      end

      def zone_expression
        @zone_expression ||= find_expression Fare::Validity::Expression::Zone
      end

      def zone_to_zone_expression
        @zone_to_zone_expression ||= find_expression Fare::Validity::Expression::ZoneToZone
      end
    end
  end
end
