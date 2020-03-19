class Export::Gtfs < Export::Base
  include LocalExportSupport

  option :duration, required: true, type: :integer, default_value: 200
  option :prefer_referent_stop_area, required: true, type: :boolean, default_value: false

  DEFAULT_AGENCY_ID = "chouette_default"

  @skip_empty_exports = true

  def zip_file_name
    @zip_file_name ||= "chouette-its-#{Time.now.to_i}"
  end

  def agency_id company
    (company.registration_number.presence || company.objectid) if company
  end

  def stop_id stop_area
    stop_area.registration_number.presence || stop_area.objectid
  end

  def generate_export_file
    tmp_dir = Dir.mktmpdir
    export_to_dir tmp_dir
    File.open File.join(tmp_dir, "#{zip_file_name}.zip")
  end

  attr_reader :target

  def export_scope
    @export_scope ||= Export::Scope::DateRange.new(referential, date_range)
  end
  attr_writer :export_scope

  # FIXME
  def journeys
    export_scope.vehicle_journeys
  end

  def export_to_dir(directory)
    operations_count = 5

    @target = GTFS::Target.new(File.join(directory, "#{zip_file_name}.zip"))

    export_companies_to target
    notify_progress 1.0/operations_count
    export_stop_areas_to target
    notify_progress 2.0/operations_count

    Lines.new(self).export!

    export_transfers_to target
    notify_progress 3.0/operations_count
    # Export Trips
    TimeTables.new(self).export!
    VehicleJourneys.new(self).export!

    notify_progress 4.0/operations_count
    # Export stop_times.txt
    VehicleJourneyAtStops.new(self).export!

    notify_progress 5.0/operations_count
    # Export files fare_rules, fare_attributes, shapes, frequencies
    # and feed_info aren't yet implemented as import nor export features from
    # the chouette model

    target.close
  end

  # For legacy specs
  def export_lines_to(target)
    @target = target
    Lines.new(self).export!
  end

  def export_companies_to(target)
    company_ids = Set.new
    # OPTIMIZEME pluck is great bu can consume a lot of memory for very large Vehicle Journey collection
    journeys.left_joins(route: { line: :company }).
      pluck("vehicle_journeys.id", "vehicle_journeys.company_id", "companies.id", "companies.time_zone").
      each do |vehicle_journey_id, vehicle_journeys_company_id, line_company_id, company_time_zone|

      company_id = vehicle_journeys_company_id.presence || line_company_id.presence || DEFAULT_AGENCY_ID
      company_ids << company_id

      index.register_vehicle_journey_time_zone vehicle_journey_id, company_time_zone if company_time_zone
    end

    Chouette::Company.where(id: company_ids-[DEFAULT_AGENCY_ID]).order('name').find_each do |company|
      if company.time_zone.present?
        time_zone = company.time_zone
      else
        time_zone = "Etc/GMT"
        args = {
          criticity: :info,
          message_key: :no_timezone,
          message_attributes: {
            company_name: company.name
          }
        }
        self.messages.create args
      end
      a_id = agency_id(company)

      target.agencies << {
        id: a_id,
        name: company.name,
        url: company.default_contact_url,
        timezone: time_zone,
        phone: company.default_contact_phone,
        email: company.default_contact_email
        #lang: TO DO
        #fare_url: TO DO
      }

      index.register_agency_id(company, a_id)
    end

    if company_ids.include? DEFAULT_AGENCY_ID
      target.agencies << {
        id: DEFAULT_AGENCY_ID,
        name: "Default Agency",
        timezone: "Etc/GMT",
      }
    end
  end

  def exported_stop_areas
    Chouette::StopArea.union(export_scope.stop_areas, Chouette::StopArea.parents_of(export_scope.stop_areas.where(area_type: 'zdep'))).where(kind: :commercial)
  end

  def export_stop_areas_to(target)
    CustomFieldsSupport.within_workgroup(referential.workgroup) do
      exported_stop_areas.includes(:referent, :parent).find_each do |stop_area|

        stop_id = stop_id(stop_area)

        if prefer_referent_stop_area && stop_area.referent
          stop_id = stop_id(stop_area.referent)
          index.register_stop_id(stop_area, stop_id)

          stop_area = stop_area.referent
        end

        index.register_stop_id stop_area, stop_id

        target.stops << {
          id: stop_id,
          name: stop_area.name,
          location_type: stop_area.area_type == 'zdep' ? 0 : 1,
          parent_station: (stop_id(stop_area.parent) if stop_area.parent),
          lat: stop_area.latitude,
          lon: stop_area.longitude,
          desc: stop_area.comment,
          url: stop_area.url,
          timezone: (stop_area.time_zone unless stop_area.parent),
          #code: TO DO
          #wheelchair_boarding: TO DO wheelchair_boarding <=> mobility_restricted_suitability ?
        }
      end
    end
  end

  def export_transfers_to(target)
    stop_ids = exported_stop_areas.select(:id).to_sql
    connections = referential.stop_area_referential.connection_links.where("departure_id IN (#{stop_ids}) AND arrival_id IN (#{stop_ids})")
    transfers = {}
    stops = connections.map do |c|
      # all transfers are both ways
      key = [stop_id(c.departure), stop_id(c.arrival)].sort
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

  class Index

    def initialize
      @stop_ids = {}
      @route_ids = {}
      @agency_ids = {}
      @trip_ids = Hash.new { |h,k| h[k] = [] }
      @service_ids = Hash.new { |h,k| h[k] = [] }
      @vehicle_journey_time_zones = {}
      @trip_index = 0
    end

    def stop_id(stop_area_id)
      @stop_ids[stop_area_id]
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

    def vehicle_journey_time_zone(vehicle_journey_id)
      @vehicle_journey_time_zones[vehicle_journey_id]
    end

    def register_vehicle_journey_time_zone(vehicle_journey_id, time_zone)
      @vehicle_journey_time_zones[vehicle_journey_id] = time_zone
    end

  end

  class Part

    attr_reader :export
    def initialize(export)
      @export = export
    end

    delegate :target, :index, :export_scope, :messages, :date_range, to: :export

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
        decorated_line = Decorator.new(line, index)

        create_messages decorated_line
        target.routes << decorated_line.route_attributes

        index.register_route_id line, decorated_line.route_id
      end
    end

    class Decorator < SimpleDelegator

      # index is optional to make tests easier
      def initialize(line, index = nil)
        super line
        @index = index
      end

      attr_reader :index

      def route_id
        registration_number.presence || objectid
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
        self.class.route_types[transport_mode]
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
      time_tables.find_each do |time_table|
        if time_table.periods.length > 0
          decorated_time_table = Decorator.new(time_table, index, date_range)
        else
          decorated_time_table = NoPeriodDecorator.new(time_table, index, date_range)
        end

        decorated_time_table.handle_periods

        decorated_time_table.calendars.each { |c| target.calendars << c }
        decorated_time_table.calendar_dates.each { |cd| target.calendar_dates << cd }

        index.register_service_ids time_table, decorated_time_table.service_ids
      end
    end

    class Decorator < SimpleDelegator
      # index is optional to make tests easier
      def initialize(time_table, index = nil, export_date_range = nil)
        super time_table
        @index = index
        @export_date_range = export_date_range
        @calendars = []
        @calendar_dates = []
        @service_ids = []
      end

      attr_reader :index, :calendars, :calendar_dates, :service_ids

      def handle_periods
        time_table_dates = dates.to_a

        periods.each do |period|
          next unless @export_date_range.nil? || (period.range & @export_date_range)

          service_id = period.id
          @calendars << {
            service_id: service_id,
            start_date: period.period_start.strftime('%Y%m%d'),
            end_date: period.period_end.strftime('%Y%m%d'),
            monday: monday ? 1:0,
            tuesday: tuesday ? 1:0,
            wednesday: wednesday ? 1:0,
            thursday: thursday ? 1:0,
            friday: friday ? 1:0,
            saturday: saturday ? 1:0,
            sunday: sunday ? 1:0
          }

          @service_ids << service_id

          time_table_dates.delete_if do |time_table_date|
            if ((!time_table_date.in_out && (period.range === time_table_date.date)) ||
              (time_table_date.in_out && (@export_date_range === time_table_date.date)))
              @calendar_dates << {
                service_id: service_id,
                date: time_table_date.date.strftime('%Y%m%d'),
                exception_type: time_table_date.in_out ? 1 : 2
              }
            end
            true
          end
        end
      end
    end

    class NoPeriodDecorator < SimpleDelegator
      # index is optional to make tests easier
      def initialize(time_table, index = nil, export_date_range)
        super time_table
        @index = index
        @export_date_range = export_date_range
        @calendar_dates = []
      end

      attr_reader :index, :calendar_dates

      def handle_periods
        time_table_dates = dates.to_a
        service_id = self.id

        dates.each do |date|
          if time_table_date.in_out && (@export_date_range === time_table_date.date)
            @calendar_dates << {
              service_id: service_id,
              date: time_table_date.date.strftime('%Y%m%d'),
              exception_type: 1
            }
          end
        end
      end

      def calendars
        []
      end

      def service_ids
        [service_id]
      end

      def service_id
        self.id
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
      vehicle_journeys.find_each do |vehicle_journey|

        decorated_vehicle_journey = Decorator.new(vehicle_journey, index)

        vehicle_journey.time_tables.each do |time_table|
          index.service_ids(time_table.id).each do |service_id|
            index.increment_trip_index

            target.trips << decorated_vehicle_journey.trip_attributes(service_id)

            index.register_trip_id vehicle_journey, decorated_vehicle_journey.trip_id
          end
        end
      end
    end

    class Decorator < SimpleDelegator

      # index is optional to make tests easier
      def initialize(vehicle_journey, index = nil)
        super vehicle_journey
        @index = index
      end

      attr_reader :index

      def route_id
        index.route_id(route.line_id)
      end

      def trip_id
        "trip_#{index.trip_index}"
      end

      def direction_id
        route.wayback == 'outbound' ? 0 : 1
      end

      def trip_attributes service_id
        {
          route_id: route_id,
          service_id:  service_id,
          id: trip_id,
          #headsign: TO DO
          short_name: published_journey_name,
          direction_id: (direction_id if route.wayback.present?),
          #block_id: TO DO
          #shape_id: TO DO
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

    delegate :vehicle_journey_at_stops, to: :export_scope

    def export!
      vehicle_journey_at_stops.
        includes(:stop_point).
        joins(stop_point: :stop_area).
        where("stop_areas.kind" => "commercial").
        find_each do |vehicle_journey_at_stop|

        decorated_vehicle_journey_at_stop = Decorator.new(vehicle_journey_at_stop, index)

        # Duplicate the stop time for each exported trip
        index.trip_ids(vehicle_journey_at_stop.vehicle_journey_id).each do |trip_id|
          route_attributes = decorated_vehicle_journey_at_stop.stop_time_attributes
          route_attributes.merge!(trip_id: trip_id)

          target.stop_times << route_attributes
        end
      end
    end

    class Decorator < SimpleDelegator

      # index is optional to make tests easier
      def initialize(vehicle_journey_at_stop, index = nil)
        super vehicle_journey_at_stop
        @index = index
      end

      attr_reader :index

      delegate :position, to: :stop_point

      def time_zone
        index&.vehicle_journey_time_zone(vehicle_journey_id)
      end

      def stop_time_departure_time
        GTFS::Time.format_datetime departure_time, departure_day_offset, time_zone if departure_time
      end

      def stop_time_arrival_time
        GTFS::Time.format_datetime arrival_time, arrival_day_offset, time_zone if arrival_time
      end

      def stop_area_id
        __getobj__.stop_area_id.presence || stop_point.stop_area_id
      end

      def stop_time_stop_id
        index&.stop_id(stop_area_id)
      end

      def stop_time_attributes
        { departure_time: stop_time_departure_time,
          arrival_time: stop_time_arrival_time,
          stop_id: stop_time_stop_id,
          stop_sequence: position }
      end

    end

  end
end
