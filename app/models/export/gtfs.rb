# frozen_string_literal: true

module Export
  class Gtfs < Export::Base
    include LocalExportSupport

    option :period, default_value: 'all_periods', enumerize: %w[all_periods only_next_days static_day_period]
    option :duration
    option :from, serialize: ActiveModel::Type::Date
    option :to, serialize: ActiveModel::Type::Date
    option :exported_lines, default_value: 'all_line_ids',
                            enumerize: %w[line_ids company_ids line_provider_ids all_line_ids]
    option :exported_code_space
    option :line_ids, serialize: :map_ids
    option :company_ids, serialize: :map_ids
    option :line_provider_ids, serialize: :map_ids
    option :prefer_referent_stop_area, required: true, default_value: false, enumerize: [true, false],
                                       serialize: ActiveModel::Type::Boolean
    option :prefer_referent_line, required: true, default_value: false, enumerize: [true, false],
                                  serialize: ActiveModel::Type::Boolean
    option :prefer_referent_company, required: true, default_value: false, enumerize: [true, false],
                                     serialize: ActiveModel::Type::Boolean
    option :ignore_parent_stop_places, required: true, default_value: false, enumerize: [true, false],
                                       serialize: ActiveModel::Type::Boolean
    option :ignore_extended_gtfs_route_types, required: true, default_value: false, enumerize: [true, false],
                                              serialize: ActiveModel::Type::Boolean

    # TODO: No longer used by present in database. Remove me
    option :ignore_single_stop_station, required: false, default_value: false, enumerize: [true, false], serialize: ActiveModel::Type::Boolean

    validate :ensure_is_valid_period

    def ensure_is_valid_period
      return unless period == 'static_day_period'

      return unless from.blank? || to.blank? || from > to

      errors.add(:from, :invalid)
      errors.add(:to, :invalid)
    end

    DEFAULT_AGENCY_ID = 'chouette_default'
    DEFAULT_TIMEZONE = 'Etc/UTC'

    @skip_empty_exports = true

    def export_file
      @export_file ||= Tempfile.new(["export-gtfs-#{id}", '.zip'])
    end

    def target
      @target ||= GTFS::Target.new(export_file)
    end

    def generate_export_file
      [
        Companies,

        StopAreas,

        Lines,

        ConnectionLinks,

        Shapes,

        # Export Trips
        TimeTables,
        VehicleJourneys,

        # Export stop_times.txt
        JourneyPatternDistances,
        VehicleJourneyAtStops,

        VehicleJourneyCompanies,
        Contracts,

        FeedInfo,

        FareProducts,
        FareValidities
      ].each do |part_class|
        part_class.new(self).perform
      end

      target.close

      export_file
    end

    # For legacy specs
    def export_lines_to(target)
      @target = target
      Lines.new(self).perform
    end

    def export_companies_to(target)
      @target = target
      Companies.new(self).perform
    end

    alias ignore_parent_stop_places? ignore_parent_stop_places

    def index
      @index ||= Index.new
    end

    # For the moment, the GTFS Export doesn't support 'no' code space
    def code_space
      @code_space ||= super || workgroup.code_spaces.default
    end

    delegate :shape_referential, :line_referential, :stop_area_referential, :fare_referential, to: :workgroup

    def export_scope=(export_scope)
      @export_scope = Scope.new(export_scope, export: self)
    end

    def export_scope
      @export_scope ||= Scope.new(super, export: self)
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
        @trip_ids = Hash.new { |h, k| h[k] = [] }
        @services = Hash.new { |h, k| h[k] = [] }
        @flexible = {}
        @journey_pattern_distances = {}
      end

      def register_journey_pattern_distance(journey_pattern_id, stop_point_id, value)
        @journey_pattern_distances[[journey_pattern_id, stop_point_id]] = value
      end

      def journey_pattern_distance(journey_pattern_id, stop_point_id)
        return unless journey_pattern_id && stop_point_id

        @journey_pattern_distances[[journey_pattern_id, stop_point_id]]
      end

      def register_services(time_table, services)
        @services[time_table.id] = services
      end

      def services(time_table_id)
        @services[time_table_id]
      end

      def register_trip_id(vehicle_journey, trip_id)
        @trip_ids[vehicle_journey.id] << trip_id
      end

      def trip_ids(vehicle_journey_id)
        @trip_ids[vehicle_journey_id]
      end

      def register_flexible(vehicle_journey, flexible_service)
        @flexible[vehicle_journey.id] = flexible_service
      end

      def flexible?(vehicle_journey_id)
        @flexible[vehicle_journey_id]
      end
    end

    class Scope < Export::Base::Scope
      concerning :StopAreas do
        def stop_areas
          @stop_areas ||=
            if prefer_referent_stop_areas?
              scoped_stop_areas.referents_or_self
            else
              scoped_stop_areas
            end
        end

        def ignore_parent_stop_places?
          export.ignore_parent_stop_places
        end

        def prefer_referent_stop_areas?
          export.prefer_referent_stop_area
        end

        def referenced_stop_areas
          return Chouette::StopArea.none unless prefer_referent_stop_areas?

          scoped_stop_areas.particulars.with_referent
        end

        def dependencies_stop_areas
          @dependencies_stop_areas ||=
            if prefer_referent_stop_areas?
              scoped_stop_areas.self_and_referents
            else
              scoped_stop_areas
            end
        end

        def entrances
          stop_area_referential.entrances.where(stop_area: dependencies_stop_areas)
        end

        def connection_links
          stop_area_referential.connection_links.where(departure: dependencies_stop_areas,
                                                       arrival: dependencies_stop_areas)
        end

        def scoped_stop_areas
          if ignore_parent_stop_places?
            current_scope.stop_areas
          else
            current_scope.stop_areas.self_and_parents
          end
        end
      end

      concerning :Lines do
        def lines
          if prefer_referent_lines?
            scoped_lines.referents_or_self
          else
            scoped_lines
          end
        end

        def prefer_referent_lines?
          export.prefer_referent_line
        end

        def referenced_lines
          return Chouette::Line.none unless prefer_referent_lines?

          scoped_lines.particulars.with_referent
        end

        def dependencies_lines
          @dependencies_lines ||=
            if prefer_referent_lines?
              scoped_lines.self_and_referents
            else
              scoped_lines
            end
        end

        def scoped_lines
          current_scope.lines
        end

        def contracts
          (workbench || workgroup).contracts.with_lines(dependencies_lines)
        end
      end

      concerning :Companies do
        def companies
          if prefer_referent_companies?
            scoped_companies.referents_or_self
          else
            scoped_companies
          end
        end

        def prefer_referent_companies?
          export.prefer_referent_company
        end

        def referenced_companies
          return Chouette::Company.none unless prefer_referent_companies?

          scoped_companies.particulars.with_referent
        end

        def dependencies_companies
          @dependencies_companies ||=
            if prefer_referent_companies?
              scoped_companies.self_and_referents
            else
              scoped_companies
            end
        end

        def fare_products
          fare_referential.fare_products.where(company: dependencies_companies)
        end

        def fare_validities
          fare_referential.fare_validities.by_products(fare_products)
        end

        def scoped_companies
          line_referential.companies.where(id: dependencies_lines.with_company.distinct.pluck(:company_id))
        end
      end
    end

    class Part < Export::Part
      callback Operation::CustomFieldIgnored

      delegate :index, to: :export

      def decorator_attributes
        {
          index: index
        }
      end
    end

    class ModelDecorator < Export::Decorator
      alias gtfs_identifier model_code

      attr_accessor :index

      def gtfs_attributes
        {
          id: gtfs_identifier
        }
      end
    end

    def default_company
      @default_company ||=
        begin
          company_id, = export_scope.lines.group(:company_id).order(count_all: :desc).limit(1).count.first
          return nil unless company_id

          company = line_referential.companies.find(company_id)
          company = company.referent if prefer_referent_company && company.referent
          company
        end
    end

    def default_timezone
      @default_timezone ||= default_company&.time_zone || DEFAULT_TIMEZONE
    end

    class StopAreas < Part
      delegate :stop_areas, :referenced_stop_areas, to: :export_scope
      delegate :public_code_space, to: :export
      delegate :code_space, to: :export # TODO CHOUETTE-4496 temporary

      def perform
        referenced_stop_areas.pluck(:id, :referent_id).each do |model_id, referent_id|
          code_provider.stop_areas.alias(model_id, as: referent_id)
        end

        stop_areas.includes(:referent, :parent, :codes, :fare_zones).find_each do |stop_area|
          decorated_stop_area = decorate(stop_area, public_code_space: public_code_space, code_space: code_space)
          target.stops << decorated_stop_area.gtfs_attributes
        end
      end

      class Decorator < ModelDecorator
        attr_accessor :public_code_space
        attr_accessor :code_space # TODO CHOUETTE-4496 temporary

        def gtfs_zone_id
          # TODO CHOUETTE-4496 this is correct code to restore
          # code_provider.code(default_fare_zone)

          zone_id
        end

        # TODO CHOUETTE-4496 #zone_id, #code_value and #fare_zone_codes are temporary
        def zone_id
          code_value || default_fare_zone&.uuid
        end

        def code_value
          return unless fare_zone_codes

          fare_zone_codes.find { |code| code.code_space && code.code_space == code_space }&.value
        end

        def fare_zone_codes
          default_fare_zone&.codes
        end

        def default_fare_zone
          @default_fare_zone ||= fare_zones&.first
        end

        def gtfs_parent_station
          code_provider.stop_areas.code parent_id
        end

        def gtfs_platform_code
          public_code.presence
        end

        def gtfs_stop_code
          codes.find { |code| code.code_space_id == public_code_space.id }&.value
        end

        def gtfs_wheelchair_boarding
          case wheelchair_accessibility
          when nil, 'unknown'
            '0'
          when 'yes'
            '1'
          when 'no'
            '2'
          end
        end

        def gtfs_location_type
          quay? ? 0 : 1
        end

        def has_parent_station?
          quay? && parent_id.present?
        end

        def gtfs_timezone
          time_zone unless has_parent_station?
        end

        def gtfs_attributes
          super.merge(
            name: name,
            code: gtfs_stop_code,
            location_type: gtfs_location_type,
            parent_station: gtfs_parent_station,
            lat: latitude,
            lon: longitude,
            desc: comment,
            url: url,
            timezone: gtfs_timezone,
            wheelchair_boarding: gtfs_wheelchair_boarding,
            platform_code: gtfs_platform_code,
            zone_id: gtfs_zone_id
          )
        end
      end
    end

    class Companies < Part
      delegate :companies, :referenced_companies, :lines, to: :export_scope

      def perform
        referenced_companies.pluck(:id, :referent_id).each do |model_id, referent_id|
          code_provider.companies.alias(model_id, as: referent_id)
        end

        companies.find_each do |company|
          decorated_company = decorate company

          create_messages decorated_company unless decorated_company.valid?
          target.agencies << decorated_company.gtfs_attributes
        end

        return unless lines.without_company.exists?

        target.agencies << default_agency
      end

      def default_agency
        {
          id: DEFAULT_AGENCY_ID,
          name: 'Default Agency',
          timezone: DEFAULT_TIMEZONE
        }
      end

      class Decorator < ModelDecorator
        def timezone
          time_zone.presence || DEFAULT_TIMEZONE
        end

        def gtfs_attributes
          super.merge(
            name: name,
            url: default_contact_url,
            timezone: timezone,
            phone: default_contact_phone,
            email: default_contact_email,
            lang: default_language,
            fare_url: fare_url
          )
        end

        def validate
          messages.add :no_timezone if time_zone.blank?
        end
      end
    end

    class Lines < Part
      delegate :lines, :referenced_lines, to: :export_scope

      def perform
        referenced_lines.pluck(:id, :referent_id).each do |model_id, referent_id|
          code_provider.lines.alias(model_id, as: referent_id)
        end

        lines.find_each do |line|
          decorated_line = decorate(line)
          create_messages decorated_line unless decorated_line.valid?

          target.routes << decorated_line.gtfs_attributes
        end
      end

      def ignore_extended_gtfs_route_types?
        export.ignore_extended_gtfs_route_types
      end

      def decorator_attributes
        super.merge(
          ignore_extended_gtfs_route_types: ignore_extended_gtfs_route_types?
        )
      end

      class Decorator < ModelDecorator
        attr_accessor :ignore_extended_gtfs_route_types

        def route_long_name
          value = published_name.presence || name
          value unless value == route_short_name
        end

        def route_short_name
          number
        end

        def self.base_route_type_mapper # rubocop:disable Metrics/MethodLength
          @base_route_type_mapper ||= Chouette::TransportMode.mapper do
            register :tram, 0
            register :metro, 1
            register :rail, 2
            register :bus, 3
            register :water, 4
            register 'funicular/street_cable_car', 5
            register :telecabin, 6
            register :funicular, 7
            register :trolley_bus, 11
            register 'rail/monorail', 12
            register :coach, 3
            register :air, 1100
            register :taxi, 1500
            register :hire_car, 1506
          end
        end

        def self.extended_route_type_mapper
          @extended_route_type_mapper ||= base_route_type_mapper.append do
            register :coach, 200
            register 'rail/interregional_rail', 103
            register 'coach/regional_coach', 204
            register 'coach/special_coach', 205
            register 'coach/commuter_coach', 208
            register 'bus/school_and_public_service_bus', 713
          end
        end

        def route_type_mapper
          ignore_extended_gtfs_route_types ? self.class.base_route_type_mapper : self.class.extended_route_type_mapper
        end

        def route_type
          return 715 if flexible_service? && !ignore_extended_gtfs_route_types

          route_type_mapper.for chouette_transport_mode
        end

        def default_agency?
          route_agency_id == DEFAULT_AGENCY_ID
        end

        def validate
          messages.add :no_company, criticity: :info if default_agency?
        end

        def route_agency_id
          code_provider.companies.code(company_id) || DEFAULT_AGENCY_ID
        end

        def gtfs_attributes
          super.merge(
            agency_id: route_agency_id,
            long_name: route_long_name,
            short_name: route_short_name,
            type: route_type,
            desc: comment,
            url: url,
            color: color,
            text_color: text_color
          )
        end
      end
    end

    class TimeTables < Part
      delegate :time_tables, to: :export_scope

      def perform
        time_tables.includes(:periods, :dates).find_each do |time_table|
          decorated_time_table = decorate time_table

          decorated_time_table.calendars.each { |c| target.calendars << c }
          decorated_time_table.calendar_dates.each { |cd| target.calendar_dates << cd }

          index.register_services time_table, decorated_time_table.services
        end
      end

      class Decorator < ModelDecorator
        def services_by_id
          @services_by_id ||= Hash.new { |h, service_id| h[service_id] = Service.new(service_id) }
        end

        def service(service_id)
          services_by_id[service_id]
        end

        def services
          services_by_id.values
        end

        def decorated_periods
          @decorated_periods ||= periods.map { |period| PeriodDecorator.new(period) }
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
          model_code
        end

        def period_service_id(decorated_period)
          if first_period? decorated_period
            default_service_id
          else
            [default_service_id, decorated_period.calendar_service_id].join('-')
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

        %w[monday tuesday wednesday thursday friday saturday sunday].each do |day|
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
      TimeTables.new(self).perform
      VehicleJourneys.new(self).perform
    end

    class VehicleJourneys < Part
      delegate :vehicle_journeys, to: :export_scope
      delegate :shape_referential, to: :export

      def decorator_attributes
        super.merge(
          bikes_allowed_resolver: bikes_allowed_resolver
        )
      end

      def perform
        vehicle_journeys.includes(:time_tables, :journey_pattern, :accessibility_assessment, :codes, route: :line).find_each do |vehicle_journey|
          decorated_vehicle_journey = decorate(vehicle_journey)

          decorated_vehicle_journey.services.each do |service|
            trip_attributes = decorated_vehicle_journey.trip_attributes(service)

            target.trips << trip_attributes
            index.register_trip_id vehicle_journey, trip_attributes[:id]

            flexible_service = vehicle_journey.line.flexible_service? || false
            index.register_flexible vehicle_journey, flexible_service
          end
        end
      end

      def bikes_allowed_resolver
        @bikes_allowed_resolver ||= BikesAllowedResolver.new(
          service_facility_sets: shape_referential&.service_facility_sets
        )
      end

      class BikesAllowedResolver
        def initialize(service_facility_sets: nil)
          @service_facility_sets = service_facility_sets
        end

        attr_reader :service_facility_sets

        def for_associated_services(associated_services)
          if associated_services.find { |a| a.code == 'luggage_carriage/cycles_allowed' }
            '1'
          elsif associated_services.find { |a| a.code == 'luggage_carriage/no_cycles' }
            '2'
          else
            '0'
          end
        end

        def for_service_facility_set(service_facility_set)
          for_associated_services(service_facility_set.associated_services)
        end

        def for_service_facility_sets(service_facility_sets)
          sole(service_facility_sets.map { |set| for_service_facility_set(set) })
        end

        def for_service_facility_set_id(service_facility_set_id)
          cache[service_facility_set_id] ||= for_service_facility_set(
            service_facility_sets.find(service_facility_set_id)
          )
        end

        def for_service_facility_set_ids(service_facility_set_ids)
          sole(service_facility_set_ids.map { |id| for_service_facility_set_id(id) })
        end

        def sole(values)
          values.uniq!
          values.clear if values.many?

          values.first || '0'
        end

        def cache
          @cache ||= {}
        end

        def for_vehicle_journey(vehicle_journey)
          if service_facility_sets
            for_service_facility_set_ids(vehicle_journey.service_facility_set_ids)
          else
            for_service_facility_sets(vehicle_journey.service_facility_sets)
          end
        end
      end

      class Decorator < ModelDecorator
        attr_writer :bikes_allowed_resolver

        def bikes_allowed_resolver
          @bikes_allowed_resolver ||= BikesAllowedResolver.new
        end

        def route_id
          code_provider.lines.code route.line_id if route
        end

        def trip_id(service)
          if service == preferred_service
            base_trip_id
          else
            "#{base_trip_id}-#{service.id}"
          end
        end

        alias base_trip_id model_code

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
          return unless route && route.wayback.present?

          route.wayback == 'outbound' ? 0 : 1
        end

        def gtfs_shape_id
          code_provider.shapes.code journey_pattern&.shape_id
        end

        def gtfs_headsign
          journey_pattern&.published_name
        end

        def gtfs_wheelchair_accessibility
          assessment = accessibility_assessment || line

          case assessment&.wheelchair_accessibility
          when nil, 'unknown'
            '0'
          when 'yes'
            '1'
          when 'no'
            '2'
          end
        end

        def gtfs_bikes_allowed
          bikes_allowed_resolver&.for_vehicle_journey(self)
        end

        def trip_attributes(service)
          {
            route_id: route_id,
            service_id: service.id,
            id: trip_id(service),
            short_name: published_journey_name,
            direction_id: direction_id,
            shape_id: gtfs_shape_id,
            headsign: gtfs_headsign,
            wheelchair_accessible: gtfs_wheelchair_accessibility,
            bikes_allowed: gtfs_bikes_allowed
            # block_id: TO DO
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

    class JourneyPatternDistances < Part
      def journey_patterns
        export_scope.journey_patterns.includes(:stop_points).where.not(costs: [{}, nil])
      end

      def perform
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

    class VehicleJourneyAtStops < Part
      delegate :vehicle_journey_at_stops, to: :export_scope

      def perform
        vehicle_journey_at_stops.find_each_light do |light_vehicle_journey_at_stop|
          decorated_vehicle_journey_at_stop = decorate(light_vehicle_journey_at_stop)

          # Duplicate the stop time for each exported trip
          index.trip_ids(light_vehicle_journey_at_stop.vehicle_journey_id).each do |trip_id|
            route_attributes = decorated_vehicle_journey_at_stop.gtfs_attributes
            route_attributes.merge!(trip_id: trip_id)
            target.stop_times << route_attributes
          end
        end
      end

      def ignore_time_zone?
        return @ignore_time_zone unless @ignore_time_zone.nil?

        @ignore_time_zone ||= !export_scope.stop_areas.with_time_zone.exists?
      end

      def default_timezone
        return nil if ignore_time_zone?

        export.default_timezone
      end

      def vehicle_journey_at_stops
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

        export_scope.vehicle_journey_at_stops.joins(:stop_point, :vehicle_journey).select(*attributes)
      end

      def decorator_attributes
        super.merge(
          default_timezone: default_timezone
        )
      end

      class Decorator < ModelDecorator
        attr_accessor :default_timezone

        def shape_dist_traveled
          return unless journey_pattern_id && stop_point_id

          journey_pattern_distance = index.journey_pattern_distance(journey_pattern_id, stop_point_id)
          return unless journey_pattern_distance

          journey_pattern_distance.to_f / 1000
        end

        def time_zone
          default_timezone
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
          super || parent_stop_area_id
        end

        def stop_time_stop_id
          code_provider.stop_areas.code stop_area_id
        end

        def flexible?
          index&.flexible?(vehicle_journey_id)
        end

        def drop_off_type
          return 1 if for_alighting == 'forbidden'
          flexible? ? 2 : 0
        end

        def pickup_type
          return 1 if for_boarding == 'forbidden'
          flexible? ? 2 : 0
        end

        def gtfs_attributes
          { departure_time: stop_time_departure_time,
            arrival_time: stop_time_arrival_time,
            stop_id: stop_time_stop_id,
            stop_sequence: position,
            pickup_type: pickup_type,
            drop_off_type: drop_off_type,
            shape_dist_traveled: shape_dist_traveled }
        end
      end
    end

    class Shapes < Part
      delegate :shapes, to: :export_scope

      def perform
        shapes.find_each do |shape|
          decorated_shape = decorate(shape)
          target.shapes << decorated_shape.gtfs_shape
        end
      end

      class Decorator < ModelDecorator
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
          GTFS::Shape.new(id: model_code).tap do |shape|
            gtfs_shape_points.each { |point| shape.points << point }
          end
        end
      end
    end

    class VehicleJourneyCompanies < Part
      def perform
        vehicle_journeys.find_each do |vehicle_journey|
          decorate(vehicle_journey).attributions.each do |attribution|
            target.attributions << attribution
          end
        end
      end

      def vehicle_journeys
        export_scope.vehicle_journeys.joins(route: :line).where.not(company: nil).where('vehicle_journeys.company_id != lines.company_id')
      end

      class Decorator < ModelDecorator
        alias vehicle_journey model

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
            is_operator: is_operator
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

    class Contracts < Part
      delegate :contracts, to: :export_scope

      def perform
        contracts.find_each do |contract|
          decorate(contract).attributions.each do |attribution|
            target.attributions << attribution
          end
        end
      end

      class Decorator < ModelDecorator
        def route_id(line)
          code_provider.code(line)
        end

        def attributions
          lines.map do |line|
            associated_route_id = route_id(line)
            # Ensure the associated Line is into the export scope
            if associated_route_id.present?
              attributes = attribution_attributes.merge(route_id: route_id(line))
              GTFS::Attribution.new attributes
            end
          end.compact
        end

        def attribution_attributes
          {
            organization_name: organization_name,
            is_producer: is_producer,
            attribution_id: attribution_id
          }
        end

        def organization_name
          company&.name
        end

        def is_producer
          1
        end

        def attribution_id
          SecureRandom.uuid
        end
      end
    end

    class FeedInfo < Part
      delegate :validity_period, to: :export_scope
      delegate :default_company, to: :export

      def perform
        target.feed_infos << Decorator.new(company: company, validity_period: validity_period).feed_info_attributes
      end

      alias company default_company

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
      delegate :fare_products, to: :export_scope

      def perform
        fare_products.find_each do |fare_product|
          decorated_product = decorate(fare_product)
          target.fare_attributes << decorated_product.fare_attribute
        end
      end

      class Decorator < ModelDecorator
        def gtfs_attributes
          {
            fare_id: model_code,
            price: gtfs_price,
            agency_id: gtfs_agency_id,
            # Not managed for the moment
            currency_type: 'EUR',
            payment_method: 1,
            transfers: 0,
            transfer_duration: nil
          }
        end

        def gtfs_price
          price_cents.to_f / 100
        end

        def gtfs_agency_id
          code_provider.companies.code company_id
        end

        def fare_attribute
          GTFS::FareAttribute.new gtfs_attributes
        end
      end
    end

    class FareValidities < Part
      delegate :fare_validities, to: :export_scope

      def perform
        fare_validities.includes(:products).find_each do |fare_validity|
          decorated_validity = decorate(fare_validity)

          decorated_validity.fare_rules.each do |fare_rule|
            target.fare_rules << fare_rule
          end
        end
      end

      class Decorator < ModelDecorator
        def fare_rules
          products.map do |fare_product|
            GTFS::FareRule.new attributes.merge(fare_id: fare_id(fare_product))
          end
        end

        def fare_id(fare_product)
          code_provider.code(fare_product)
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
          code_provider.lines.code line_expression.line_id if line_expression
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

        def zone_gtfs_code(fare_zone)
          code_provider.code(fare_zone)
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

    class ConnectionLinks < Part
      delegate :connection_links, to: :export_scope

      def perform
        connection_links.each do |connection_link|
          target.transfers << decorate(connection_link).gtfs_attributes
        end
      end

      class Decorator < ModelDecorator
        def gtfs_min_transfer_time
          default_duration
        end

        def gtfs_from_stop_id
          code_provider.stop_areas.code(departure_id)
        end

        def gtfs_to_stop_id
          code_provider.stop_areas.code(arrival_id)
        end

        def gtfs_type
          '2'
        end

        def gtfs_attributes
          {
            from_stop_id: gtfs_from_stop_id,
            to_stop_id: gtfs_to_stop_id,
            type: gtfs_type,
            min_transfer_time: gtfs_min_transfer_time
          }
        end
      end
    end
  end
end
