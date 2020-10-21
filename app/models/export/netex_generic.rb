class Export::NetexGeneric < Export::Base
  include LocalExportSupport

  option :profile, collection: %w(european)
  option :duration, type: :integer

  def target
    @target ||= Netex::Target.build export_file, profile: netex_profile
  end
  attr_writer :target

  def export_scope
    @export_scope ||= duration ? Export::Scope::DateRange.new(referential, date_range) : Export::Scope::All.new
  end
  attr_writer :export_scope


  def netex_profile
    @netex_profile ||= Netex::Profile.create(profile) if profile
  end

  def quay_registry
    @quay_registry ||= QuayRegistry.new
  end

  def export_file
    @export_file ||= Tempfile.new(["export#{id}",'.zip'])
  end

  def generate_export_file
    CustomFieldsSupport.within_workgroup(referential.workgroup) do
      operations_count = 9

      Stops.new(self).export_part
      notify_progress 1.0/operations_count

      Stations.new(self).export_part
      notify_progress 2.0/operations_count

      Lines.new(self).export_part
      notify_progress 3.0/operations_count

      Companies.new(self).export_part
      notify_progress 4.0/operations_count

      Routes.new(self).export_part
      notify_progress 5.0/operations_count

      StopPoints.new(self).export_part
      notify_progress 6.0/operations_count

      JourneyPatterns.new(self).export_part
      notify_progress 7.0/operations_count

      VehicleJourneys.new(self).export_part
      notify_progress 8.0/operations_count

      TimeTables.new(self).export_part
      notify_progress 9.0/operations_count

    end

    target.close
    File.open export_file
  end

  class Part
    attr_reader :export

    def initialize(export, options = {})
      @export = export
      options.each { |k,v| send "#{k}=", v }
    end

    # delegate :target, :index, :export_scope, :messages, :date_range, :code_spaces, to: :export
    delegate :target, :quay_registry, :export_scope, to: :export

    def part_name
      @part_name ||= self.class.name.demodulize.underscore
    end

    def export_part
        export!
    end

  end

  class QuayRegistry

    def quay?(stop_id)
      !quays_index.has_key? stop_id
    end

    def quays_for(parent_station)
      quays_index[parent_station]
    end

    def register(netex_quay, parent_station:)
      quays_index[parent_station] << netex_quay
    end

    protected

    def quays_index
      @quays_index ||= Hash.new { |h,k| h[k] = [] }
    end

  end

  class StopDecorator < SimpleDelegator

    def netex_attributes
        attrs = {
          id: objectid,
          name: name
          # longitude: longitude,
          # latitude: latitude
        }
      end

    def parent_site_ref
      Netex::Reference.new(parent.objectid, type: 'ParentSiteRef')
    end

    def place_types
      [Netex::Reference.new(type_of_place, type: 'TypeOfPlaceRef')]
    end

    def type_of_place
      case area_type
      when 'zdep'
        'quay'
      when 'zdlp'
        'monomodalStopPlace'
      when 'lda'
        'generalStopPlace'
      when 'gdl'
          'groupOfStopPlaces'
      end
    end

    def netex_resource
      netex_resource_class.new(netex_attributes).tap do |stop|
        unless netex_resource_class.is_a?(Netex::Quay)
          stop.parent_site_ref = parent_site_ref if parent_id
          stop.place_types = place_types
        end
      end
    end

    def netex_quay?
      area_type == 'zdep'
    end

    def netex_resource_class
      parent_id && area_type == 'zdep' ? Netex::Quay : Netex::StopPlace
    end

  end

  class Stops < Part

    delegate :stop_areas, to: :export_scope

    def export!
      stop_areas.where(area_type: 'zdep').find_each do |stop_area|

        decorated_stop = StopDecorator.new(stop_area)

        netex_resource = decorated_stop.netex_resource
        if netex_resource.is_a?(Netex::Quay)
          quay_registry.register netex_resource,
                                 parent_station: decorated_stop.parent_id
        else
          target << netex_resource
        end
      end
    end

  end

  class Stations < Part

    delegate :stop_areas, to: :export_scope

    def export!
      stop_areas.where.not(area_type: 'zdep').find_each do |stop_area|

        decorated_stop = StopDecorator.new(stop_area)

        stop_place = decorated_stop.netex_resource
        stop_place.quays = quay_registry.quays_for(decorated_stop.id)

        target << stop_place
      end
    end

  end

  class Lines < Part

    delegate :lines, to: :export_scope

    def export!
      lines.find_each do |line|
        decorated_line = Decorator.new(line)
        target << decorated_line.netex_resource
      end
    end

    class Decorator < SimpleDelegator

      def netex_attributes
        {
          id: objectid,
          name: name,
          transport_mode: transport_mode,
          transport_submode: transport_submode,
          operator_ref: operator_ref
        }
      end

      def netex_resource
        Netex::Line.new netex_attributes
      end

      def operator_ref
        Netex::Reference.new(company.objectid, type: 'OperatorRef')
      end

    end

  end

  class Companies < Part

    delegate :companies, to: :export_scope

    def export!
      companies.find_each do |company|
        decorated_company = Decorator.new(company)
        target << decorated_company.netex_resource
      end
    end

    class Decorator < SimpleDelegator

      def netex_attributes
        {
          id: id,
          name: name
        }
      end

      def netex_resource
        Netex::Operator.new netex_attributes
      end

    end

  end

  class StopPointDecorator < SimpleDelegator

    attr_accessor :journey_pattern_id
    def initialize(stop_point, journey_pattern_id = nil)
      super stop_point
      @journey_pattern_id = journey_pattern_id
    end

    def point_on_route
      Netex::PointOnRoute.new point_on_route_attributes
    end

    def point_on_route_attributes
      {
        id: point_on_route_id,
        order: position,
        route_point_ref: route_point_ref
      }
    end

    def point_on_route_id
      objectid.sub('StopPoint', 'PointOnRoute')
    end

    def route_point_ref
      Netex::Reference.new(route_point_ref_id, type: 'RoutePointRef')
    end

    def route_point_ref_id
      objectid.sub('StopPoint', 'RoutePoint')
    end

    def scheduled_stop_point
      Netex::ScheduledStopPoint.new(scheduled_stop_point_attributes)
    end

    def scheduled_stop_point_attributes
      {
        id: scheduled_stop_point_id
      }
    end

    def scheduled_stop_point_id
      @scheduled_stop_point_id ||= objectid.sub('StopPoint', 'ScheduledStopPoint')
    end

    def passenger_stop_assignment
      Netex::PassengerStopAssignment.new(passenger_stop_assignment_attributes).tap do |passenger_stop_assignment|
        if stop_area.area_type == 'zdep'
          passenger_stop_assignment.quay_ref = quay_ref
        else
          passenger_stop_assignment.stop_place_ref = stop_place_ref
        end
      end
    end

    def passenger_stop_assignment_attributes
      {
        id: passenger_stop_assignment_id,
        order: 0,
        scheduled_stop_point_ref: scheduled_stop_point_ref
      }
    end

    def passenger_stop_assignment_id
      objectid.sub('StopPoint', 'PassengerStopAssignment')
    end

    def scheduled_stop_point_ref
      Netex::Reference.new(scheduled_stop_point_id, type: 'ScheduledStopPointRef')
    end

    def quay_ref
      Netex::Reference.new(stop_area.objectid, type: 'QuayRef')
    end

    def stop_place_ref
      Netex::Reference.new(stop_area.objectid, type: 'StopPlaceRef')
    end

    def route_point
      Netex::RoutePoint.new(route_point_attributes)
    end

    def route_point_attributes
      {
        id: route_point_id,
        projections: point_projection
      }
    end

    def route_point_id
      objectid.sub('StopPoint', 'RoutePoint')
    end

    def point_projection
      [Netex::PointProjection.new(point_projection_attributes)]
    end

    def point_projection_attributes
      {
        id: point_projection_id,
        project_to_point_ref: project_to_point_ref
      }
    end

    def point_projection_id
      objectid.sub('StopPoint', 'PointProjection')
    end

    def project_to_point_ref
      Netex::Reference.new(scheduled_stop_point_id, type: 'ProjectToPointRef')
    end

    def stop_point_in_journey_pattern
      Netex::StopPointInJourneyPattern.new stop_point_in_journey_pattern_attributes
    end

    def stop_point_in_journey_pattern_attributes
      {
        id: stop_point_in_journey_pattern_id,
        order: position,
        scheduled_stop_point_ref: scheduled_stop_point_ref
      }
    end

    def stop_point_in_journey_pattern_id
      jp_match = journey_pattern_id.match /^chouette:JourneyPattern:(.+):LOC$/
      sp_match = objectid.match /^chouette:JourneyPattern:(.+):LOC$/
      if jp_match.nil? || sp_match.nil?
        return journey_pattern_id+objectid
      end
      "chouette:StopPointInJourneyPattern:#{jp_match[1]}-#{sp_match[1]}:LOC"
    end
  end

  class Routes < Part

    delegate :routes, to: :export_scope

    def export!
      routes.find_each do |route|
        decorated_route = Decorator.new(route)
        target << decorated_route.netex_resource
      end
    end

    class Decorator < SimpleDelegator

      def netex_attributes
        {
          id: id,
          name: netex_name,
          line_ref: line_ref,
          points_in_sequence: points_in_sequence
        }
      end

      def netex_resource
        Netex::Route.new netex_attributes
      end

      def netex_name
        published_name.presence || name
      end

      def line_ref
        Netex::Reference.new(line.objectid, type: 'LineRef')
      end

      def points_in_sequence
        decorated_stop_points.map(&:point_on_route)
      end

      def decorated_stop_points
        @decorated_stop_points ||= stop_points.map do |stop_point|
            StopPointDecorator.new stop_point
        end
      end

    end

  end

  class StopPoints < Part

    delegate :stop_points, to: :export_scope

    def export!
      stop_points.find_each do |stop_point|
        decorated_stop_point = StopPointDecorator.new(stop_point)
        target << decorated_stop_point.scheduled_stop_point
        target << decorated_stop_point.passenger_stop_assignment
        target << decorated_stop_point.route_point
      end
    end

  end

  class JourneyPatterns < Part

    delegate :journey_patterns, to: :export_scope

    def export!
      journey_patterns.find_each do |journey_pattern|
        decorated_journey_pattern = Decorator.new(journey_pattern)
        target << decorated_journey_pattern.netex_resource
      end
    end

    class Decorator < SimpleDelegator

      def netex_attributes
        {
          id: objectid,
          name: name,
          route_ref: route_ref,
          points_in_sequence: points_in_sequence
        }
      end

      def netex_resource
        Netex::JourneyPattern.new netex_attributes
      end

      def route_ref
        Netex::Reference.new(route.objectid, type: 'RouteRef')
      end

      def points_in_sequence
        decorated_stop_points.map(&:stop_point_in_journey_pattern)
      end

      def decorated_stop_points
        @decorated_stop_points ||= stop_points.map do |stop_point|
            StopPointDecorator.new(stop_point, objectid)
        end
      end
    end

  end

  class VehicleJourneys < Part

    delegate :vehicle_journeys, to: :export_scope

    def export!
      vehicle_journeys.find_each do |vehicle_journey|
        decorated_vehicle_journey = Decorator.new(vehicle_journey)
        target << decorated_vehicle_journey.netex_resource
      end
    end

    class Decorator < SimpleDelegator

      def netex_attributes
        {
          id: objectid,
          name: published_journey_name,
          journey_pattern_ref: journey_pattern_ref,
          passing_times: passing_times,
          day_types: day_types
        }
      end

      def netex_resource
        Netex::ServiceJourney.new netex_attributes
      end

      def journey_pattern_ref
        Netex::Reference.new(journey_pattern.objectid, type: 'JourneyPatternRef')
      end

      def passing_times
        decorated_vehicle_journey_at_stops.map(&:timetabled_passing_time)
      end

      def decorated_vehicle_journey_at_stops
        @decorated_vehicle_journey_at_stops ||= vehicle_journey_at_stops.map do |vehicle_journey_at_stop|
          VehicleJourneyAtStopDecorator.new(vehicle_journey_at_stop, journey_pattern.objectid)
        end
      end

      def day_types
        decorated_time_tables.map(&:day_type_ref)
      end

      def decorated_time_tables
        @decorated_time_tables ||= time_tables.map do |time_table|
          TimeTableDecorator.new(time_table)
        end
      end

    end

    class VehicleJourneyAtStopDecorator < SimpleDelegator

      attr_accessor :journey_pattern_id
      def initialize(vehicle_journey_at_stop, journey_pattern_id)
        super vehicle_journey_at_stop
        @journey_pattern_id = journey_pattern_id
      end

      def timetabled_passing_time
        Netex::TimetabledPassingTime.new.tap do |passing_time|
          passing_time.stop_point_in_journey_pattern_ref = stop_point_in_journey_pattern_ref
          passing_time.departure_time = netex_time(departure_local_time_of_day)
          passing_time.departure_day_offset = departure_local_time_of_day.day_offset
          passing_time.arrival_time = netex_time(arrival_local_time_of_day)
          passing_time.arrival_day_offset = arrival_local_time_of_day.day_offset
        end
      end

      def stop_point_in_journey_pattern_ref
        decorated_stop_point = StopPointDecorator.new(stop_point, journey_pattern_id)
        Netex::Reference.new(decorated_stop_point.stop_point_in_journey_pattern_id, type: 'StopPointInJourneyPatternRef')
      end

      def netex_time time_of_day
        Netex::Time.new time_of_day.hour, time_of_day.minute, time_of_day.second
      end
    end

  end

  class TimeTableDecorator < SimpleDelegator

    def netex_resources
      [day_type] + exported_periods + exported_dates
    end

    def day_type
      Netex::DayType.new day_type_attributes
    end

    def day_type_attributes
      {
        id: objectid,
        name: comment,
        properties: properties
      }
    end

    def day_type_ref
      @day_type_ref ||= Netex::Reference.new(objectid, type: 'DayTypeRef')
    end

    def properties
      [Netex::PropertyOfDay.new(days_of_week: days_of_week)]
    end

    DAYS = %w{monday tuesday wednesday thursday friday saturday sunday}
    def days_of_week
      DAYS.map { |day| day.capitalize if send(day) }.join(' ')
    end

    def exported_periods
      decorated_periods.map(&:operating_period) + decorated_periods.map(&:day_type_assignment)
    end

    def decorated_periods
      @decorated_periods ||= periods.map do |period|
        PeriodDecorator.new(period, day_type_ref)
      end
    end

    def exported_dates
      decorated_dates.map(&:day_type_assignment)
    end

    def decorated_dates
      @decorated_dates ||= dates.map do |date|
        PeriodDecorator.new(date, day_type_ref)
      end
    end

  end

  class PeriodDecorator < SimpleDelegator

    attr_accessor :day_type_ref
    def initialize(period, day_type_ref)
      super period
      @day_type_ref = day_type_ref
    end

    def operating_period
      Netex::OperatingPeriod.new operating_period_attributes
    end

    def operating_period_attributes
      {
        id: id,
        from_date: period_start.to_datetime,
        to_date:period_end.to_datetime
      }
    end

    def day_type_assignment
      Netex::DayTypeAssignment.new day_type_assignment_attributes
    end

    def day_type_assignment_attributes
      {
        id: id,
        operating_period_ref: operating_period_ref,
        day_type_ref: day_type_ref,
        order: 0
      }
    end

    def operating_period_ref
      Netex::Reference.new(id, type: 'OperatinPeriodRef')
    end

  end

  class DateDecorator < SimpleDelegator

    attr_accessor :day_type_ref
    def initialize(date, day_type_ref)
      super date
      @day_type_ref = day_type_ref
    end

    def day_type_assignment
      Netex::DayTypeAssignment.new day_type_assignment_attributes
    end

    def day_type_assignment_attributes
      {
        id: id,
        date: date,
        is_available: in_out,
        day_type_ref: day_type_ref,
        oerder: 0
      }
    end

    def operatiing_period_ref
      Netex::Reference.new(objectid, type: 'OperatinPeriodRef')
    end

  end

  class TimeTables < Part
    delegate :time_tables, to: :export_scope

    def export!
      time_tables.find_each do |time_table|
        decorated_time_table = TimeTableDecorator.new(time_table)
        decorated_time_table.netex_resources.each do |resource|
          target << resource
        end
      end
    end

  end

end
