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
  delegate :shape_referential, to: :workgroup

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

  def point_of_interests
    shape_referential.point_of_interests
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
      VehicleJourneyAtStops,
      VehicleJourneys,
      VehicleJourneyStopAssignments,
      Organisations,
      PointOfInterests
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

    delegate :target, :resource_tagger, :export_scope, :workgroup, to: :export

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
      tag_index[line.id] = {
        line_id: line.objectid,
        line_name: line.name,
        operator_id: line.company&.objectid,
        operator_name: line.company&.name
      }
    end

    protected

    def tag_index
      @tag_index ||= Hash.new { |h,k| h[k] = {} }
    end
  end

  class AlternateIdentifiersExtractor

    def initialize(model)
      @model = model
    end
    attr_reader :model

    delegate :registration_number, :codes, to: :model

    def registration_number_value
      if has_registration_number?
        [[ "external", registration_number ]]
      else
        []
      end
    end

    def has_registration_number?
      model.respond_to?(:registration_number) && registration_number.present?
    end

    def has_codes?
      model.respond_to? :codes
    end

    def codes_values
      if has_codes?
        codes.map do |code|
          [ code.code_space.short_name, code.value ]
        end
      else
        []
      end
    end

    def alternate_identifiers_values
      registration_number_value + codes_values
    end

    def alternate_identifiers
      alternate_identifiers_values.map do |key, value|
        Netex::KeyValue.new key: key, value: value, type_of_key: "ALTERNATE_IDENTIFIER"
      end
    end

  end

  class CustomFieldExtractor

    def initialize(model)
      @model = model
    end
    attr_reader :model

    delegate :custom_field_values, to: :model, allow_nil: true

    def custom_field_identifiers
      return [] unless custom_field_values.present?

      custom_field_values.map do |key, value|
        Netex::KeyValue.new key: key, value: value, type_of_key: "chouette::custom-field"
      end
    end

  end

  class StopDecorator < SimpleDelegator

    def netex_attributes # rubocop:disable Metrics/MethodLength
      {
        id: netex_identifier,
        derived_from_object_ref: derived_from_object_ref,
        name: name,
        public_code: public_code,
        centroid: centroid,
        raw_xml: import_xml,
        key_list: key_list,
        accessibility_assessment: accessibility_assessment
      }.tap do |attributes|
        unless netex_quay?
          attributes[:parent_site_ref] = parent_site_ref
          attributes[:place_types] = place_types
        end
      end
    end

    def netex_identifier
      @netex_identifier ||= Netex::ObjectId.parse(objectid)
    end

    def accessibility_assessment
      return unless accessibility_assessment?

      Netex::AccessibilityAssessment.new(
        id: netex_identifier.change(type: 'AccessibilityAssessment').to_s,
        mobility_impaired_access: netex_value(mobility_impaired_accessibility),
        limitations: [accessibility_limitation].compact,
        validity_conditions: [availability_condition].compact
      )
    end

    def accessibility_limitation
      return unless accessibility_limitation?

      Netex::AccessibilityLimitation.new(
        wheelchair_access: netex_value(wheelchair_accessibility),
        step_free_access: netex_value(step_free_accessibility),
        escalator_free_access: netex_value(escalator_free_accessibility),
        lift_free_access: netex_value(lift_free_accessibility),
        audible_signals_available: netex_value(audible_signals_availability),
        visual_signs_available: netex_value(visual_signs_availability)
      )
    end

    def netex_value(value)
      case value
      when 'yes'
        'true'
      when 'no'
        'false'
      else
        value
      end
    end

    def availability_condition
      return unless accessibility_limitation_description.present?

      Netex::AvailabilityCondition.new(
        id: netex_identifier.change(type: 'AvailabilityCondition').to_s,
        description: accessibility_limitation_description
      )
    end

    def accessibility_assessment?
      accessibility_limitation? || availability_condition.present? || mobility_impaired_accessibility != 'unknown'
    end

    def accessibility_limitation?
      %i[
        wheelchair_accessibility step_free_accessibility escalator_free_accessibility
        lift_free_accessibility audible_signals_availability visual_signs_availability
      ].any? do |attribute|
        send(attribute) != :unknown
      end
    end

    def parent_objectid
      parent&.objectid
    end

    def derived_from_object_ref
      referent&.objectid
    end

    def key_list
      netex_alternate_identifiers + netex_custom_field_identifiers
    end

    def netex_alternate_identifiers
      AlternateIdentifiersExtractor.new(self).alternate_identifiers
    end

    def netex_custom_field_identifiers
      CustomFieldExtractor.new(self).custom_field_identifiers
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
      area_type&.to_sym == Chouette::AreaType::QUAY
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
          address_line_1: address_line_1,
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

  class PointOfInterests < Part

    def export!
      point_of_interests.find_each do |point_of_interest|
        decorated_point_of_interest = Decorator.new(point_of_interest)
        target << decorated_point_of_interest.netex_resource
      end
    end

    def point_of_interests
      export.point_of_interests
        .includes(:codes, :point_of_interest_hours)
        .joins(:point_of_interest_category)
        .select(
          "point_of_interests.*",
          "point_of_interest_categories.name AS category_name"
        )
    end

    class Decorator < SimpleDelegator

      def netex_attributes
        {
          id: uuid,
          name: name,
          url: url,
          centroid: centroid,
          postal_address: postal_address,
          key_list: key_list,
          operating_organisation_view: operating_organisation_view,
          classifications: classifications,
          validity_conditions: validity_conditions,
        }
      end

      def netex_resource
        Netex::PointOfInterest.new(netex_attributes)
      end

      def centroid
        return unless longitude || latitude

        Netex::Point.new(
          location: Netex::Location.new(longitude: longitude, latitude: latitude)
        )
      end

      def postal_address
        Netex::PostalAddress.new(
          id: uuid,
          address_line_1: address_line_1,
          post_code: zip_code,
          town: city_name,
          country_name: country
        )
      end

      def operating_organisation_view
        Netex::OperatingOrganisationView.new(
          contact_details: Netex::ContactDetails.new(
            phone: phone,
            email: email
          )
        )
      end

      def classifications
        [ Netex::PointOfInterestClassificationView.new(name: category_name) ]
      end

      def key_list
        AlternateIdentifiersExtractor.new(self).alternate_identifiers
      end

      def validity_conditions
        [].tap do |validity_conditions|
          point_of_interest_hours.find_each do |hour|
            validity_condition = ValidityCondition.new(hour, uuid)
            validity_conditions << Netex::AvailabilityCondition.new(
              day_types: validity_condition.day_types,
              timebands: validity_condition.timebands
            )
          end
        end
      end

      class ValidityCondition
        def initialize(hour, uuid)
          @hour = hour
          @uuid = uuid
        end
        attr_accessor :hour, :uuid

        def timebands
          [
            Netex::Timeband.new(
              id: id,
              start_time: start_time,
              end_time: end_time
            )
          ]
        end

        def day_types
          [
            Netex::DayType.new(
              id: id,
              properties: properties
            )
          ]
        end

        private

        def id
          "#{uuid}-#{hour.id}"
        end

        def start_time
          hour.opening_time_of_day.to_hms
        end

        def end_time
          hour.closing_time_of_day.to_hms
        end

        def properties
          [ Netex::PropertyOfDay.new(days_of_week: days_of_week) ]
        end

        def days_of_week
          all_days
            .select{ |day| contains_day?(day) }
            .map{ |day| day.to_s.capitalize }
            .join(' ')
        end

        def all_days
          @all_days ||= Timetable::DaysOfWeek.all.days
        end

        def contains_day?(day)
          hour.week_days.send("#{day}?")
        end
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
        AlternateIdentifiersExtractor.new(self).alternate_identifiers
      end

      def netex_name
        name || published_name
      end

      def valid_between
        return unless active_from.present? || active_until.present?

        from_date = active_from.present? ? active_from.beginning_of_day : nil
        to_date = active_until.present? ? (active_until + 1).beginning_of_day : nil

        Netex::ValidBetween.new(
          from_date: from_date,
          to_date: to_date
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
        }.tap do |attributes|
          if netex_alternate_identifiers.present?
            attributes[:key_list] = netex_alternate_identifiers
          end
        end
      end

      def netex_resource
        Netex::Operator.new netex_attributes
      end

      def netex_alternate_identifiers
        AlternateIdentifiersExtractor.new(self).alternate_identifiers
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
        data_source_ref: route_data_source_ref,
      }
    end

    def route_data_source_ref
      __getobj__.try(:route_data_source_ref) || route&.data_source_ref
    end

    def stop_area_objectid
      __getobj__.try(:stop_area_objectid) || stop_area&.objectid
    end

    def stop_area_area_type
      __getobj__.try(:stop_area_area_type) || stop_area&.area_type
    end

    def scheduled_stop_point_id
      @scheduled_stop_point_id ||= netex_identifier.change(type: 'ScheduledStopPoint').to_s if netex_identifier
    end

    def netex_quay?
      stop_area_area_type&.to_sym == Chouette::AreaType::QUAY
    end

    def passenger_stop_assignment
      Netex::PassengerStopAssignment.new(passenger_stop_assignment_attributes).tap do |passenger_stop_assignment|
        if netex_quay?
          passenger_stop_assignment.quay_ref = quay_ref
        else
          passenger_stop_assignment.stop_place_ref = stop_place_ref
        end
      end
    end

    def passenger_stop_assignment_attributes
      {
        id: passenger_stop_assignment_id,
        data_source_ref: route_data_source_ref,
        order: 0,
        scheduled_stop_point_ref: scheduled_stop_point_ref
      }
    end

    def passenger_stop_assignment_id
      netex_identifier.change(type: 'PassengerStopAssignment').to_s if netex_identifier
    end

    def scheduled_stop_point_ref
      Netex::Reference.new(scheduled_stop_point_id, type: 'ScheduledStopPointRef')
    end

    def quay_ref
      Netex::Reference.new(stop_area_objectid, type: 'QuayRef')
    end

    def stop_place_ref
      Netex::Reference.new(stop_area_objectid, type: 'StopPlaceRef')
    end

    def route_point
      Netex::RoutePoint.new(route_point_attributes)
    end

    def route_point_attributes
      {
        id: route_point_id,
        projections: point_projection,
        data_source_ref: route_data_source_ref
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

    def self.stop_point_in_journey_pattern_id(stop_point_objectid, journey_pattern_objectid)
      merged_object_id = Netex::ObjectId.merge(journey_pattern_objectid, stop_point_objectid, type: "StopPointInJourneyPattern")

      if merged_object_id
        merged_object_id.to_s
      else
        "#{journey_pattern_objectid}-#{stop_point_objectid}"
      end
    end

    def stop_point_in_journey_pattern_id
      self.class.stop_point_in_journey_pattern_id(netex_identifier, journey_pattern_id)
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
      stop_points.joins(:route, :stop_area).select(selected).find_each_light do |stop_point|
        tags = resource_tagger.tags_for(stop_point.line_id)
        tagged_target = TaggedTarget.new(target, tags)

        decorated_stop_point = StopPointDecorator.new(stop_point)
        tagged_target << decorated_stop_point.scheduled_stop_point
        tagged_target << decorated_stop_point.passenger_stop_assignment
        tagged_target << decorated_stop_point.route_point
      end
    end

    private

    def selected
      [
        'stop_points.*',
        'stop_areas.objectid AS stop_area_objectid',
        'stop_areas.area_type AS stop_area_area_type',
        'routes.line_id AS line_id',
        'routes.data_source_ref AS route_data_source_ref',
      ]
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

  class VehicleJourneyAtStops < Part
    def export!
      vehicle_journey_at_stops.find_each_light do |light_vehicle_journey_at_stop|
        decorated_vehicle_journey_at_stop = Decorator.new(light_vehicle_journey_at_stop)
        target << decorated_vehicle_journey_at_stop.netex_resource
      end
    end

    def vehicle_journey_at_stops
      export_scope.vehicle_journey_at_stops
        .joins(stop_point: :stop_area, vehicle_journey: { journey_pattern: :route })
        .order(:vehicle_journey_id, "stop_points.position": :asc)
        .select(
          "vehicle_journey_at_stops.*",
          "journey_patterns.objectid AS journey_pattern_objectid",
          "vehicle_journeys.objectid AS vehicle_journey_objectid",
          "stop_points.objectid AS stop_point_objectid",
          "stop_areas.time_zone AS time_zone",
        )
    end

    class Decorator < SimpleDelegator
      def netex_attributes
        {
          departure_time: stop_time_departure_time,
          arrival_time: stop_time_arrival_time,
          departure_day_offset: departure_day_offset,
          arrival_day_offset: arrival_day_offset,
          stop_point_in_journey_pattern_ref: stop_point_in_journey_pattern_ref,
        }
      end

      def netex_resource
        Netex::TimetabledPassingTime.new(netex_attributes).with_tag(parent_id: parent_id)
      end

      def netex_identifier
        @netex_identifier ||= Netex::ObjectId.parse(stop_point_objectid)
      end

      def parent_id
        vehicle_journey_objectid
      end

      def journey_pattern_objectid
        __getobj__.try(:journey_pattern_objectid) || journey_pattern&.objectid
      end

      def stop_point_objectid
        __getobj__.try(:stop_point_objectid) || stop_point&.objectid
      end

      def stop_point_in_journey_pattern_id
        StopPointDecorator.stop_point_in_journey_pattern_id(stop_point_objectid, journey_pattern_objectid)
      end

      def stop_point_in_journey_pattern_ref
        Netex::Reference.new(stop_point_in_journey_pattern_id, type: Netex::StopPointInJourneyPattern)
      end

      def netex_time time_of_day
        Netex::Time.new time_of_day.hour, time_of_day.minute, time_of_day.second
      end

      def stop_time_arrival_time
        netex_time arrival_local_time_of_day if arrival_local_time_of_day
      end

      def stop_time_departure_time
        netex_time departure_local_time_of_day if departure_local_time_of_day
      end
    end
  end

  class VehicleJourneys < Part

    def export!
      vehicle_journeys.find_each do |vehicle_journey|
        tags = resource_tagger.tags_for(vehicle_journey.line_id)
        tagged_target = TaggedTarget.new(target, tags)

        decorated_vehicle_journey = Decorator.new(vehicle_journey, code_space_keys)
        tagged_target << decorated_vehicle_journey.netex_resource
      end
    end

    def vehicle_journeys
      Query.new(export_scope.vehicle_journeys).scope
    end

    def code_space_keys
      @code_space_keys ||= workgroup.code_spaces.pluck(:id, :short_name).to_h
    end

    class Query

      def initialize(vehicle_journeys)
        @vehicle_journeys = vehicle_journeys
      end
      attr_accessor :vehicle_journeys

      def scope
        scope = vehicle_journeys.joins(journey_pattern: :route).select(selected)

        scope = scope.left_joins(:codes).select(vehicle_journey_codes).group(group_by)

        if vehicle_journeys.joins_values.include? :time_tables
          scope = scope.select(time_table_objectids)
        end

        scope
      end

      private

      def selected
        <<~SQL
          vehicle_journeys.*,
          routes.line_id AS line_id,
          journey_patterns.objectid AS journey_pattern_objectid
        SQL
      end

      def time_table_objectids
        <<~SQL
          array_agg(time_tables.objectid) AS time_table_objectids
        SQL
      end

      def vehicle_journey_codes
        <<~SQL
          array_agg(
            jsonb_build_object(
              'id', referential_codes.code_space_id,
              'value', referential_codes.value
            )
          ) AS vehicle_journey_codes
        SQL
      end

      def group_by
        <<~SQL
          vehicle_journeys.id,
          routes.line_id,
          journey_patterns.objectid
        SQL
      end
    end

    class Decorator < SimpleDelegator

      def initialize(vehicle_journey, code_space_keys = nil)
        super vehicle_journey
        @code_space_keys = code_space_keys
      end
      attr_accessor :code_space_keys

      def netex_attributes
        {
          id: objectid,
          data_source_ref: data_source_ref,
          name: published_journey_name,
          journey_pattern_ref: journey_pattern_ref,
          public_code: published_journey_identifier,
          day_types: day_types
        }.tap do |attributes|
          if netex_alternate_identifiers
            attributes[:key_list] = netex_alternate_identifiers
          end
        end
      end

      def netex_resource
        Netex::ServiceJourney.new netex_attributes
      end

      def code_space_key(code_space_id)
        code_space_keys[code_space_id]
      end

      def netex_alternate_identifiers
        return if code_space_keys.blank? || try(:vehicle_journey_codes).blank?

        vehicle_journey_codes.map do |vehicle_journey_code|
          Netex::KeyValue.new({
            key: code_space_key(vehicle_journey_code['id'].to_i),
            value: vehicle_journey_code['value'],
            type_of_key: "ALTERNATE_IDENTIFIER"
          })
        end
      end

      def journey_pattern_ref
        Netex::Reference.new(journey_pattern_objectid, type: 'JourneyPatternRef')
      end

      def journey_pattern_objectid
        __getobj__.try(:journey_pattern_objectid) || journey_pattern&.objectid
      end

      def day_types
        objectids = try(:time_table_objectids) || time_tables.pluck(:objectid)
        objectids.map do |objectid|
          Netex::Reference.new(objectid, type: 'DayTypeRef')
        end
      end
    end
  end

  class VehicleJourneyStopAssignments < Part

    def export!
      vehicle_journey_at_stops.find_each do |vehicle_journey_at_stop|
        target << Decorator.new(vehicle_journey_at_stop).netex_resource
      end
    end

    def vehicle_journey_at_stops
      export_scope.vehicle_journey_at_stops.where.not(stop_area: nil)
                  .joins(:vehicle_journey, :stop_point, :stop_area)
                  .select(
                    'vehicle_journey_at_stops.*',
                    'vehicle_journeys.objectid AS vehicle_journey_objectid',
                    "COALESCE(vehicle_journeys.data_source_ref, 'none') AS vehicle_journey_data_source_ref",
                    'stop_points.objectid AS stop_point_objectid',
                    'stop_areas.objectid AS stop_area_objectid',
                    'stop_points.position AS stop_point_position'
                  )
    end

    class Decorator < SimpleDelegator
      def netex_attributes
        {
          id: objectid,
          data_source_ref: vehicle_journey_data_source_ref,
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
        Netex::ObjectId.merge(vehicle_journey_objectid, stop_point_position, type: "VehicleJourneyStopAssignment").to_s
      end

      def stop_point_position
        __getobj__.try(:stop_point_position) || stop_point&.position
      end

      def stop_point_objectid
        __getobj__.try(:stop_point_objectid) || stop_point&.objectid
      end

      def stop_area_objectid
        __getobj__.try(:stop_area_objectid) || stop_area&.objectid
      end

      def vehicle_journey_objectid
        __getobj__.try(:vehicle_journey_objectid) || vehicle_journey&.objectid
      end

      def vehicle_journey_data_source_ref
        loaded_value = __getobj__.try(:vehicle_journey_data_source_ref)
        return nil if loaded_value == "none"

        loaded_value || vehicle_journey&.data_source_ref
      end

      def scheduled_stop_point_ref
        Netex::Reference.new(stop_point_objectid, type: 'ScheduledStopPointRef')
      end

      def stop_place_ref
        Netex::Reference.new(stop_area_objectid, type: 'StopPlaceRef')
      end

      def quay_ref
        Netex::Reference.new(stop_area_objectid, type: 'QuayRef')
      end

      def vehicle_journey_refs
        [Netex::Reference.new(vehicle_journey_objectid, type: 'ServiceJourney')]
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
