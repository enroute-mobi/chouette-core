class Export::NetexGeneric < Export::Base
  include LocalExportSupport

  option :profile, enumerize: %w(none european idfm/line idfm/full), default: :none
  option :duration
  option :line_ids, serialize: :map_ids
  option :company_ids, serialize: :map_ids
  option :line_provider_ids, serialize: :map_ids
  option :period, default_value: 'all_periods', enumerize: %w[all_periods only_next_days]
  option :exported_lines, default_value: 'all_line_ids', enumerize: %w[line_ids company_ids line_provider_ids all_line_ids]

  def target
    @target ||= Netex::Target.build export_file, profile: netex_profile, validity_periods: validity_periods
  end
  attr_writer :target

  def validity_periods
    [ referential.validity_period ]
  end

  def profile?
    ! [nil, 'none'].include? profile
  end

  def netex_profile
    @netex_profile ||= Netex::Profile.create(profile) if profile?
  end

  def content_type
    profile? ? 'application/zip' : 'text/xml'
  end

  def file_extension
    profile? ? "zip" : 'xml'
  end

  delegate :stop_area_referential, to: :workgroup

  def stop_areas
    @stop_areas ||=
      ::Query::StopArea.new(stop_area_referential.stop_areas).
        self_referents_and_ancestors(export_scope.stop_areas)
  end

  def entrances
    # Must unscope the entrances to find entrances associated with all exported Stop Areas
    # (including parent Stop Areas)
    stop_area_referential.entrances.where(stop_area: stop_areas)
  end

  def resource_tagger
    @resource_tagger ||= ResourceTagger.new
  end

  def export_file
    @export_file ||= Tempfile.new(["export#{id}",'.zip'])
  end

  def generate_export_file
    part_classes = [
      Entrances,
      Quays,
      StopPlaces,
      Companies,
      Networks,
      Lines,
      # Export StopPoints before Routes to detect local references
      StopPoints,
      Routes,
      RoutingConstraintZones,
      JourneyPatterns,
      TimeTables,
      VehicleJourneys,
      Organisations
    ]

    part_classes.each_with_index do |part_class, index|
      part_class.new(self).export_part
      notify_progress((index+1)/part_classes.count)
    end

    target.close
    export_file.close

    export_file
  end

  class TaggedTarget
    def initialize(target, tags = {})
      @target = target
      @tags = tags
    end

    def add(resource)
      resource.tags = @tags
      @target << resource
    end
    alias << add
  end

  class Part
    attr_reader :export

    def initialize(export, options = {})
      @export = export
      options.each { |k,v| send "#{k}=", v }
    end

    delegate :target, :resource_tagger, :export_scope, to: :export

    def part_name
      @part_name ||= self.class.name.demodulize.underscore
    end

    def export_part
      Chouette::Benchmark.measure part_name do
        export!
      end
    end

  end

  class ResourceTagger

    # Returns tags for several lines.
    # Returns only uniq values accross all given lines
    def tags_for_lines line_ids
      tags = Hash.new { |h,k| h[k] = Set.new }

      line_ids.each do |line_id|
        tags_for(line_id).each do |key, value|
          tags[key] << value
        end
      end

      # Remove multiple values
      tags.map do |key, set|
        [ key, set.first ] if set.size == 1
      end.compact.to_h
    end

    def tags_for line_id
      tag_index[line_id]
    end

    def register_tag_for(line)
      tag_index[line.id] = { line_id: line.objectid, line_name: line.name, operator_id: line.company&.objectid, operator_name: line.company&.name }
    end

    protected

    def tag_index
      @tag_index ||= Hash.new { |h,k| h[k] = {} }
    end
  end

  class StopDecorator < SimpleDelegator

    def netex_attributes
      {
        id: objectid,
        derived_from_object_ref: derived_from_object_ref,
        name: name,
        public_code: public_code,
        centroid: centroid,
        raw_xml: import_xml,
        key_list: netex_alternate_identifiers
      }.tap do |attributes|
        unless netex_quay?
          attributes[:parent_site_ref] = parent_site_ref
          attributes[:place_types] = place_types
        end
      end
    end

    def parent_objectid
      parent&.objectid
    end

    def derived_from_object_ref
      referent&.objectid
    end

    def netex_alternate_identifiers
      [].tap do |identifiers|
        identifiers << ["external", registration_number ] if registration_number

        codes.each do |code|
          identifiers << [code.code_space.short_name, code.value ]
        end
      end.map do |key, value|
        Netex::KeyValue.new key: key, value: value, type_of_key: "ALTERNATE_IDENTIFIER"
      end
    end

    def centroid
      Netex::Point.new(location: Netex::Location.new(longitude: longitude, latitude: latitude))
    end

    def parent_site_ref
      Netex::Reference.new(parent_objectid, type: 'StopPlace') if parent_objectid
    end

    def place_types
      [Netex::Reference.new(type_of_place, type: String)]
    end

    def type_of_place
      case area_type
      when Chouette::AreaType::QUAY
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
        if netex_quay?
          stop.with_tag parent_id: parent_objectid
        end
      end
    end

    def netex_quay?
      area_type == Chouette::AreaType::QUAY
    end

    def netex_resource_class
      netex_quay? ? Netex::Quay : Netex::StopPlace
    end
  end

  class Quays < Part

    delegate :stop_areas, to: :export

    def export!
      stop_areas.where(area_type: Chouette::AreaType::QUAY).includes(:codes, :parent, :referent).find_each do |stop_area|
        netex_resource = StopDecorator.new(stop_area).netex_resource
        target << netex_resource
      end
    end

  end

  class StopPlaces < Part

    delegate :stop_areas, to: :export

    def export!
      stop_areas.where.not(area_type: Chouette::AreaType::QUAY).includes(:codes, :entrances, :parent, :referent).find_each do |stop_area|
        stop_place = StopDecorator.new(stop_area).netex_resource
        target << stop_place
      end
    end

  end

  class Entrances < Part

    delegate :entrances, to: :export

    def export!
      entrances.includes(:raw_import).find_each do |entrance|
        decorated_entrance = Decorator.new(entrance)
        target << decorated_entrance.netex_resource
      end
    end

    class Decorator < SimpleDelegator

      def netex_attributes
        {
          id: netex_identifier,
          name: name,
          short_name: short_name,
          description: description,
          centroid: centroid,
          postal_address: postal_address,
          entrance_type: entrance_type,
          is_entry: entry?,
          is_exit: exit?,
          raw_xml: raw_xml,
        }
      end

      def netex_resource
        Netex::StopPlaceEntrance.new(netex_attributes).with_tag(parent_id: parent_objectid)
      end

      def netex_identifier
        @netex_identifier ||= Netex::ObjectId.parse(objectid)
      end

      def centroid
        Netex::Point.new(
          location: Netex::Location.new(longitude: longitude, latitude: latitude)
        )
      end

      def postal_address_objectid
        netex_identifier.change(type: 'PostalAddress').to_s
      end

      def postal_address
        Netex::PostalAddress.new(
          id: postal_address_objectid,
          address_line_1: address,
          post_code: zip_code,
          town: city_name,
          country_name: country
        )
      end

      def parent_objectid
        stop_area&.objectid
      end

      def raw_xml
        raw_import&.content
      end
    end
  end

  class Lines < Part

    delegate :lines, to: :export_scope

    def export!
      lines.includes(:company).find_each do |line|
        resource_tagger.register_tag_for line
        tags = resource_tagger.tags_for(line.id)
        tagged_target = TaggedTarget.new(target, tags)

        decorated_line = Decorator.new(line)
        tagged_target << decorated_line.netex_resource
      end
    end

    class Decorator < SimpleDelegator

      def netex_attributes
        {
          id: objectid,
          name: netex_name,
          transport_mode: transport_mode,
          transport_submode: netex_transport_submode,
          operator_ref: operator_ref,
          public_code: number,
          represented_by_group_ref: represented_by_group_ref,
          presentation: presentation,
          additional_operators: additional_operators,
          key_list: netex_alternate_identifiers,
          status: status,
          valid_between: valid_between,
          raw_xml: import_xml
        }
      end

      def netex_alternate_identifiers
        [].tap do |identifiers|
          codes.each do |code|
            identifiers << [ code.code_space.short_name, code.value ]
          end
        end.map do |key, value|
          Netex::KeyValue.new key: key, value: value, type_of_key: "ALTERNATE_IDENTIFIER"
        end
      end

      def netex_name
        name || published_name
      end

      def valid_between
        return unless active_from || active_until

        Netex::ValidBetween.new(
          from_date: active_from.beginning_of_day,
          to_date: (active_until + 1).beginning_of_day
        )
      end

      def additional_operators
        secondary_companies.map do |company|
          Netex::Reference.new(company&.objectid, type: 'OperatorRef')
        end
      end

      def status
        deactivated ? 'inactive' : ''
      end

      def netex_transport_submode
        transport_submode&.to_s unless transport_submode == :undefined
      end

      def presentation
        Netex::Presentation.new(text_colour: text_color&.downcase, colour: color&.downcase)
      end

      def netex_resource
        Netex::Line.new netex_attributes
      end

      def operator_ref
        Netex::Reference.new(company.objectid, type: 'OperatorRef') if company
      end

      def represented_by_group_ref
        Netex::Reference.new(network.objectid, type: 'NetworkRef') if network
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
          id: objectid,
          name: name,
          raw_xml: import_xml
        }
      end

      def netex_resource
        Netex::Operator.new netex_attributes
      end

    end

  end

  class Networks < Part

    delegate :networks, to: :export_scope

    def export!
      networks.find_each do |network|
        Rails.logger.debug { "Export Network #{network.inspect}" }
        decorated_network = Decorator.new(network)
        target << decorated_network.netex_resource
      end
    end

    class Decorator < SimpleDelegator

      def netex_attributes
        {
          id: objectid,
          name: name,
          raw_xml: import_xml
        }
      end

      def netex_resource
        Netex::Network.new netex_attributes
      end

    end

  end

  class StopPointDecorator < SimpleDelegator

    attr_accessor :journey_pattern_id, :route
    def initialize(stop_point, journey_pattern_id: nil, route: nil)
      super stop_point
      @journey_pattern_id = journey_pattern_id
      @route = route
    end

    def point_on_route
      Netex::PointOnRoute.new point_on_route_attributes
    end

    def point_on_route_attributes
      {
        id: point_on_route_id,
        order: netex_order,
        route_point_ref: route_point_ref
      }
    end

    def netex_order
      position+1
    end

    def netex_identifier
      @netex_identifier ||= Netex::ObjectId.parse(objectid)
    end

    def point_on_route_id
      netex_identifier.change(type: 'PointOnRoute').to_s
    end

    def route_point_ref
      Netex::Reference.new(route_point_ref_id, type: 'RoutePointRef')
    end

    def route_point_ref_id
      netex_identifier.change(type: 'RoutePoint').to_s
    end

    def scheduled_stop_point
      Netex::ScheduledStopPoint.new(scheduled_stop_point_attributes)
    end

    def scheduled_stop_point_attributes
      {
        id: scheduled_stop_point_id,
        data_source_ref: route&.data_source_ref,
      }
    end

    def scheduled_stop_point_id
      @scheduled_stop_point_id ||= netex_identifier.change(type: 'ScheduledStopPoint').to_s
    end

    def passenger_stop_assignment
      Netex::PassengerStopAssignment.new(passenger_stop_assignment_attributes).tap do |passenger_stop_assignment|
        if stop_area.area_type == Chouette::AreaType::QUAY
          passenger_stop_assignment.quay_ref = quay_ref
        else
          passenger_stop_assignment.stop_place_ref = stop_place_ref
        end
      end
    end

    def passenger_stop_assignment_attributes
      {
        id: passenger_stop_assignment_id,
        data_source_ref: route&.data_source_ref,
        order: 0,
        scheduled_stop_point_ref: scheduled_stop_point_ref
      }
    end

    def passenger_stop_assignment_id
      netex_identifier.change(type: 'PassengerStopAssignment').to_s
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
        projections: point_projection,
        data_source_ref: route&.data_source_ref
      }
    end

    def route_point_id
      netex_identifier.change(type: 'RoutePoint').to_s
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
      netex_identifier.change(type: 'PointProjection').to_s
    end

    def project_to_point_ref
      # Netex::Reference.new(scheduled_stop_point_id, type: 'ProjectToPointRef')
      Netex::Reference.new(scheduled_stop_point_id, type: 'ScheduledStopPoint')
    end

    def stop_point_in_journey_pattern
      Netex::StopPointInJourneyPattern.new stop_point_in_journey_pattern_attributes
    end

    def stop_point_in_journey_pattern_attributes
      {
        id: stop_point_in_journey_pattern_id,
        order: position+1,
        scheduled_stop_point_ref: scheduled_stop_point_ref,
        for_boarding: netex_for_boarding,
        for_alighting: netex_for_alighting
      }
    end

    def netex_for_boarding
      for_boarding == "normal"
    end

    def netex_for_alighting
      for_alighting == "normal"
    end

    def stop_point_in_journey_pattern_id
      merged_object_id = Netex::ObjectId.merge(journey_pattern_id, netex_identifier, type: "StopPointInJourneyPattern")

      if merged_object_id
        merged_object_id.to_s
      else
        "#{journey_pattern_id}-#{objectid}"
      end
    end
  end

  class Routes < Part

    delegate :routes, to: :export_scope

    def export!
      routes.includes(:line, :stop_points).find_each do |route|
        tags = resource_tagger.tags_for(route.line_id)
        tagged_target = TaggedTarget.new(target, tags)

        decorated_route = Decorator.new(route)
        # Export Direction before the Route to detect local reference
        tagged_target << decorated_route.direction if decorated_route.direction
        tagged_target << decorated_route.netex_resource

        decorated_route.routing_constraint_zones.each do |zone|
          tagged_target << zone
        end
      end
    end

    class Decorator < SimpleDelegator

      delegate :line_routing_constraint_zones, to: :line

      def netex_attributes
        {
          id: objectid,
          data_source_ref: data_source_ref,
          name: netex_name,
          line_ref: line_ref,
          direction_ref: direction_ref,
          direction_type: direction_type,
          points_in_sequence: points_in_sequence
        }.tap do |attributes|
          attributes[:direction_ref] = direction_ref if published_name.present?
        end
      end

      def netex_resource
        Netex::Route.new netex_attributes
      end

      def netex_name
        published_name.presence || name
      end

      def netex_identifier
        @netex_identifier ||= Netex::ObjectId.parse(objectid)
      end

      def direction_id
        netex_identifier.change(type: 'Direction').to_s
      end

      def direction
        @direction ||= Netex::Direction.new(
          id: direction_id,
          data_source_ref: data_source_ref,
          name: published_name
        ) if published_name
      end

      def direction_ref
        Netex::Reference.new(direction_id, type: 'DirectionRef') if direction
      end

      def direction_type
        wayback.to_s
      end

      def line_ref
        Netex::Reference.new(line.objectid, type: Netex::Line) if line
      end

      def points_in_sequence
        decorated_stop_points.map(&:point_on_route)
      end

      def decorated_stop_points
        @decorated_stop_points ||= stop_points.map do |stop_point|
          StopPointDecorator.new stop_point, route: self
        end
      end

      def stop_area_ids
        @stop_area_ids ||= stop_points.map(&:stop_area_id)
      end

      def filter_line_routing_constraint_zones
        line_routing_constraint_zones.select do |line_routing_constraint_zone|
          (line_routing_constraint_zone.stop_area_ids & stop_area_ids).many?
        end
      end

      def routing_constraint_zones
        filter_line_routing_constraint_zones.map do |line_routing_constraint_zone|
          LineRoutingConstraintZoneDecorator.new(line_routing_constraint_zone, self).netex_resource
        end
      end

      class LineRoutingConstraintZoneDecorator < SimpleDelegator
        delegate :line, to: :route

        attr_accessor :route

        def initialize(line_routing_constraint_zone, route)
          super line_routing_constraint_zone
          @route = route
        end

        def netex_attributes
          {
            id: Netex::ObjectId.merge(route.objectid, id, type: "RoutingConstraintZone"),
            name: name,
            members: scheduled_stop_point_refs,
            lines: line_refs,
            zone_use: zone_use
          }
        end

        def zone_use
          "cannotBoardAndAlightInSameZone"
        end

        def line_refs
          [Netex::Reference.new(line.objectid, type: 'LineRef')]
        end

        def stop_points
          route.stop_points.select { |stop_point| stop_area_ids.include? stop_point.stop_area_id }
        end

        def scheduled_stop_point_refs
          stop_points.map do |stop_point|
            StopPointDecorator.new(stop_point).scheduled_stop_point_ref
          end
        end

        def netex_resource
          Netex::RoutingConstraintZone.new netex_attributes
        end
      end
    end

  end

  class StopPoints < Part

    delegate :stop_points, to: :export_scope

    def export!
      stop_points.includes(:stop_area).joins(:route).select('stop_points.*', 'routes.line_id as line_id').find_each do |stop_point|
        tags = resource_tagger.tags_for(stop_point.line_id)
        tagged_target = TaggedTarget.new(target, tags)

        decorated_stop_point = StopPointDecorator.new(stop_point, route: stop_point.route)
        tagged_target << decorated_stop_point.scheduled_stop_point
        tagged_target << decorated_stop_point.passenger_stop_assignment
        tagged_target << decorated_stop_point.route_point
      end
    end

  end

  class RoutingConstraintZones < Part

    delegate :routing_constraint_zones, to: :export_scope

    def export!
      routing_constraint_zones.includes(route: :line).find_each do |routing_constraint_zone|
        tags = resource_tagger.tags_for(routing_constraint_zone.route.line_id)
        tagged_target = TaggedTarget.new(target, tags)

        decorated_zone = Decorator.new(routing_constraint_zone)
        tagged_target << decorated_zone.netex_resource
      end
    end

    class Decorator < SimpleDelegator

      def netex_attributes
        {
          id: objectid,
          data_source_ref: data_source_ref,
          name: name,
          members: scheduled_stop_point_refs,
          lines: line_refs,
          zone_use: zone_use
        }
      end

      def scheduled_stop_point_refs
        decorated_stop_points.map(&:scheduled_stop_point_ref)
      end

      def line
        route&.line
      end

      def line_refs
        [ Netex::Reference.new(line.objectid, type: 'LineRef') ] if line
      end

      def netex_resource
        Netex::RoutingConstraintZone.new netex_attributes
      end

      def zone_use
        "cannotBoardAndAlightInSameZone"
      end

      def decorated_stop_points
        stop_points.map do |stop_point|
          StopPointDecorator.new stop_point
        end
      end
    end
  end

  class JourneyPatterns < Part

    delegate :journey_patterns, to: :export_scope

    def export!
      journey_patterns.includes(:route, stop_points: :stop_area).find_each do |journey_pattern|
        tags = resource_tagger.tags_for(journey_pattern.route.line_id)
        tagged_target = TaggedTarget.new(target, tags)

        decorated_journey_pattern = Decorator.new(journey_pattern)
        # Export Destination Displays before the JourneyPattern to detect local reference
        tagged_target << decorated_journey_pattern.destination_display if journey_pattern.published_name.present?
        tagged_target << decorated_journey_pattern.netex_resource
      end
    end

    class Decorator < SimpleDelegator

      def netex_attributes
        {
          id: objectid,
          data_source_ref: data_source_ref,
          name: name,
          route_ref: route_ref,
          points_in_sequence: points_in_sequence
        }.tap do |attributes|
          attributes[:destination_display_ref] = destination_display_ref if published_name.present?
        end
      end

      def netex_resource
        Netex::ServiceJourneyPattern.new netex_attributes
      end

      def route_ref
        Netex::Reference.new(route.objectid, type: 'RouteRef')
      end

      def netex_identifier
        @netex_identifier ||= Netex::ObjectId.parse(objectid)
      end

      def destination_display_id
        netex_identifier.change(type: 'DestinationDisplay').to_s
      end

      def destination_display
        @destination_display ||= Netex::DestinationDisplay.new(
          id: destination_display_id,
          data_source_ref: data_source_ref,
          front_text: published_name
        )
      end

      def destination_display_ref
        Netex::Reference.new(destination_display_id, type: Netex::DestinationDisplay)
      end

      def points_in_sequence
        decorated_stop_points.map(&:stop_point_in_journey_pattern)
      end

      def decorated_stop_points
        @decorated_stop_points ||= stop_points.map do |stop_point|
          StopPointDecorator.new(stop_point, journey_pattern_id: objectid)
        end
      end
    end

  end

  class VehicleJourneys < Part

    delegate :vehicle_journeys, to: :export_scope

    def export!
      vehicle_journeys.includes(:time_tables, {journey_pattern: :route}, vehicle_journey_at_stops: [:stop_area, { stop_point: :stop_area }]).find_each(batch_size: 200) do |vehicle_journey|
        tags = resource_tagger.tags_for(vehicle_journey.journey_pattern.route.line_id)
        tagged_target = TaggedTarget.new(target, tags)

        decorated_vehicle_journey = Decorator.new(vehicle_journey)
        tagged_target << decorated_vehicle_journey.netex_resource

        decorated_vehicle_journey.vehicle_journey_stop_assignments.each do |assignment|
          tagged_target << assignment.netex_resource
        end
      end
    end

    class Decorator < SimpleDelegator

      def netex_attributes
        {
          id: objectid,
          data_source_ref: data_source_ref,
          name: published_journey_name,
          journey_pattern_ref: journey_pattern_ref,
          public_code: published_journey_identifier,
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

      def vehicle_journey_stop_assignments
        vehicle_journey_at_stops.select(&:stop_area_id).map do |stop|
          VehicleJourneyStopAssignmentDecorator.new(stop, self)
        end
      end

      # Ensure VehicleJourneyAtStops are well ordered by position (see CHOUETTE-1263)
      def vehicle_journey_at_stops
        @vehicle_journey_at_stops ||= super.sort_by { |s| s.stop_point.position }
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
        decorated_stop_point = StopPointDecorator.new(stop_point, journey_pattern_id: journey_pattern_id)
        Netex::Reference.new(decorated_stop_point.stop_point_in_journey_pattern_id, type: 'StopPointInJourneyPatternRef')
      end

      def netex_time time_of_day
        Netex::Time.new time_of_day.hour, time_of_day.minute, time_of_day.second
      end
    end

    class VehicleJourneyStopAssignmentDecorator < SimpleDelegator
      attr_reader :vehicle_journey

      def initialize(vehicle_journey_at_stop, vehicle_journey)
        super vehicle_journey_at_stop
        @vehicle_journey = vehicle_journey
      end

      def netex_attributes
        {
          id: objectid,
          data_source_ref: vehicle_journey.data_source_ref,
          scheduled_stop_point_ref: scheduled_stop_point_ref,
          stop_place_ref: stop_place_ref,
          quay_ref: quay_ref,
          vehicle_journey_refs: vehicle_journey_refs
        }
      end

      def netex_resource
        Netex::VehicleJourneyStopAssignment.new netex_attributes
      end

      def objectid
        name, _type, uuid, loc = vehicle_journey.objectid.split(':')

        "#{name}:VehicleJourneyStopAssignment:#{uuid}:#{loc}-#{stop_point.position}"
      end

      def scheduled_stop_point_ref
        Netex::Reference.new(stop_point.objectid, type: 'ScheduledStopPointRef')
      end

      def stop_place_ref
        Netex::Reference.new(stop_area.objectid, type: 'StopPlaceRef')
      end

      def quay_ref
        Netex::Reference.new(stop_area.objectid, type: 'QuayRef')
      end

      def vehicle_journey_refs
        [Netex::Reference.new(vehicle_journey.objectid, type: 'ServiceJourney')]
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
        data_source_ref: data_source_ref,
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
      DAYS.map { |day| day.capitalize if send(day) }.compact.join(' ')
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
        DateDecorator.new(date, day_type_ref)
      end
    end

  end

  class PeriodDecorator < SimpleDelegator

    attr_accessor :day_type_ref, :time_table
    def initialize(period, day_type_ref)
      super period
      @day_type_ref = day_type_ref

      @time_table = period.time_table
    end

    def netex_identifier
      @netex_identifier ||= Netex::ObjectId.parse(time_table.objectid)
    end

    def operating_period
      Netex::OperatingPeriod.new operating_period_attributes
    end

    def operating_period_id
      netex_identifier.merge(id, type: 'OperatingPeriod').to_s
    end

    def operating_period_attributes
      {
        id: operating_period_id,
        data_source_ref: time_table.data_source_ref,
        from_date: period_start,
        to_date: period_end
      }
    end

    def day_type_assignment_id
      netex_identifier.merge("p#{id}", type: 'DayTypeAssignment').to_s
    end

    def day_type_assignment
      Netex::DayTypeAssignment.new day_type_assignment_attributes
    end

    def day_type_assignment_attributes
      {
        id: day_type_assignment_id,
        data_source_ref: time_table.data_source_ref,
        operating_period_ref: operating_period_ref,
        day_type_ref: day_type_ref,
        order: 0
      }
    end

    def operating_period_ref
      Netex::Reference.new(operating_period_id, type: 'OperatingPeriodRef')
    end

  end

  class DateDecorator < SimpleDelegator

    attr_accessor :day_type_ref
    def initialize(date, day_type_ref)
      super date
      @day_type_ref = day_type_ref
      @time_table = date.time_table
    end

    def netex_identifier
      @netex_identifier ||= Netex::ObjectId.parse(time_table.objectid)
    end

    def day_type_assignment
      Netex::DayTypeAssignment.new day_type_assignment_attributes
    end

    def date_type_assignment_id
      netex_identifier.merge("d#{id}", type: 'DayTypeAssignment').to_s
    end

    def day_type_assignment_attributes
      {
        id: date_type_assignment_id,
        data_source_ref: time_table.data_source_ref,
        date: date,
        is_available: in_out,
        day_type_ref: day_type_ref,
        order: 0
      }
    end

  end

  class TimeTables < Part
    delegate :time_tables, to: :export_scope

    def export!
      time_tables.includes(:periods, :dates, :lines).find_each do |time_table|
        decorated_time_table = TimeTableDecorator.new(time_table)

        tags = resource_tagger.tags_for_lines(time_table.line_ids)
        tagged_target = TaggedTarget.new(target, tags)

        decorated_time_table.netex_resources.each do |resource|
          tagged_target << resource
        end
      end
    end
  end

  class Organisations < Part
    delegate :organisations, to: :export_scope

    def export!
      organisations.find_each do |o|
        target << Decorator.new(o).netex_resource
      end
    end

    class Decorator < SimpleDelegator

      def netex_resource
        Netex::GeneralOrganisation.new(id: code, name: name)
      end
    end
  end


end
